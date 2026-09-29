/*
 * qs-bt-agent: a small BlueZ pairing agent for the quickshell bar.
 *
 * Registers as the default org.bluez.Agent1 and turns every request into
 * one line on stdout. The bar answers with one line on stdin. Exits when
 * stdin closes, so the agent lives exactly as long as the bar that started
 * it, and bluetoothd stops accepting new bonds once it is gone.
 *
 * stdout:
 *   ready                                    registered as the default agent
 *   error <text>                             something went wrong (informational)
 *   confirm <id> <device> <passkey>          answer: yes <id> | no <id>
 *   authorize <id> <device>                  answer: yes <id> | no <id>
 *   service <id> <device> <uuid>             answer: yes <id> | no <id>
 *   pin <id> <device>                        answer: pin <id> <code> | no <id>
 *   passkey <id> <device>                    answer: passkey <id> <number> | no <id>
 *   show-pin <device> <code>                 type <code> on the device, no answer
 *   show-passkey <device> <passkey> <typed>  type <passkey> on the device, no answer
 *   cancel <id>                              request withdrawn, close the prompt
 *   release                                  bluetoothd dropped the agent
 *
 * stdin, besides the answers above:
 *   default                                  become the default agent again
 *                                            (another user's session may have taken over)
 *
 * <device> is the device's D-Bus path, e.g. /org/bluez/hci0/dev_50_1B_6A_4F_43_CB
 */

#include <errno.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/epoll.h>
#include <unistd.h>

#include <systemd/sd-bus.h>
#include <systemd/sd-event.h>

#define AGENT_PATH   "/org/quickshell/BluetoothAgent"
#define AGENT_IFACE  "org.bluez.Agent1"
#define CAPABILITY   "KeyboardDisplay"
#define REJECTED     "org.bluez.Error.Rejected"
#define MAX_PENDING  8

enum kind { K_FREE, K_CONFIRM, K_AUTHORIZE, K_SERVICE, K_PIN, K_PASSKEY };

struct request {
    unsigned id;
    enum kind kind;
    sd_bus_message *msg;
};

static sd_bus *bus;
static sd_event *event;
static char *bluez;                 /* unique bus name of bluetoothd, NULL if not running */
static struct request requests[MAX_PENDING];
static unsigned next_id = 1;

/* copy a string for printing, replacing anything that could break the line protocol */
static const char *clean(const char *s, bool allow_space)
{
    static char buf[256];
    size_t i = 0;

    for (; s && *s && i < sizeof(buf) - 1; s++)
        buf[i++] = (*s > ' ' && *s < 0x7f) || (allow_space && *s == ' ') ? *s : '_';
    buf[i] = '\0';
    return buf;
}

static struct request *add_request(sd_bus_message *m, enum kind kind)
{
    for (int i = 0; i < MAX_PENDING; i++) {
        if (requests[i].kind == K_FREE) {
            requests[i] = (struct request) { next_id++, kind, sd_bus_message_ref(m) };
            return &requests[i];
        }
    }
    return NULL;
}

static void drop_request(struct request *r)
{
    sd_bus_message_unref(r->msg);
    *r = (struct request) { 0 };
}

/* bluetoothd withdrew its requests (Cancel, or it went away) */
static void cancel_all(void)
{
    for (int i = 0; i < MAX_PENDING; i++) {
        if (requests[i].kind != K_FREE) {
            printf("cancel %u\n", requests[i].id);
            drop_request(&requests[i]);
        }
    }
}

static int on_method(sd_bus_message *m, void *userdata, sd_bus_error *ret_error)
{
    const char *sender = sd_bus_message_get_sender(m);
    const char *dev, *str;
    struct request *req;
    uint32_t num;
    uint16_t typed;
    int r;

    (void) userdata;
    (void) ret_error;

    if (!sd_bus_message_is_method_call(m, AGENT_IFACE, NULL))
        return 0;   /* let sd-bus reject anything else */

    /* only bluetoothd may ask us to show a prompt */
    if (!bluez || !sender || strcmp(sender, bluez) != 0) {
        r = sd_bus_reply_method_errorf(m, REJECTED, "Not from bluetoothd");
        return r < 0 ? r : 1;
    }

    if (sd_bus_message_is_method_call(m, AGENT_IFACE, "RequestConfirmation")) {
        if ((r = sd_bus_message_read(m, "ou", &dev, &num)) < 0)
            return r;
        if (!(req = add_request(m, K_CONFIRM)))
            goto busy;
        printf("confirm %u %s %06u\n", req->id, dev, num);
        return 1;   /* answered later from stdin */
    }

    if (sd_bus_message_is_method_call(m, AGENT_IFACE, "RequestAuthorization")) {
        if ((r = sd_bus_message_read(m, "o", &dev)) < 0)
            return r;
        if (!(req = add_request(m, K_AUTHORIZE)))
            goto busy;
        printf("authorize %u %s\n", req->id, dev);
        return 1;
    }

    if (sd_bus_message_is_method_call(m, AGENT_IFACE, "AuthorizeService")) {
        if ((r = sd_bus_message_read(m, "os", &dev, &str)) < 0)
            return r;
        if (!(req = add_request(m, K_SERVICE)))
            goto busy;
        printf("service %u %s %s\n", req->id, dev, clean(str, false));
        return 1;
    }

    if (sd_bus_message_is_method_call(m, AGENT_IFACE, "RequestPinCode")) {
        if ((r = sd_bus_message_read(m, "o", &dev)) < 0)
            return r;
        if (!(req = add_request(m, K_PIN)))
            goto busy;
        printf("pin %u %s\n", req->id, dev);
        return 1;
    }

    if (sd_bus_message_is_method_call(m, AGENT_IFACE, "RequestPasskey")) {
        if ((r = sd_bus_message_read(m, "o", &dev)) < 0)
            return r;
        if (!(req = add_request(m, K_PASSKEY)))
            goto busy;
        printf("passkey %u %s\n", req->id, dev);
        return 1;
    }

    if (sd_bus_message_is_method_call(m, AGENT_IFACE, "DisplayPinCode")) {
        if ((r = sd_bus_message_read(m, "os", &dev, &str)) < 0)
            return r;
        printf("show-pin %s %s\n", dev, clean(str, false));
    } else if (sd_bus_message_is_method_call(m, AGENT_IFACE, "DisplayPasskey")) {
        if ((r = sd_bus_message_read(m, "ouq", &dev, &num, &typed)) < 0)
            return r;
        printf("show-passkey %s %06u %u\n", dev, num, typed);
    } else if (sd_bus_message_is_method_call(m, AGENT_IFACE, "Cancel")) {
        cancel_all();
    } else if (sd_bus_message_is_method_call(m, AGENT_IFACE, "Release")) {
        printf("release\n");
    } else {
        return 0;
    }

    r = sd_bus_reply_method_return(m, NULL);
    return r < 0 ? r : 1;

busy:
    r = sd_bus_reply_method_errorf(m, REJECTED, "Too many requests");
    return r < 0 ? r : 1;
}

static void register_agent(void)
{
    sd_bus_error error = SD_BUS_ERROR_NULL;
    int r;

    r = sd_bus_call_method(bus, "org.bluez", "/org/bluez", "org.bluez.AgentManager1",
                           "RegisterAgent", &error, NULL, "os", AGENT_PATH, CAPABILITY);
    if (r < 0 && !sd_bus_error_has_name(&error, "org.bluez.Error.AlreadyExists"))
        goto fail;
    sd_bus_error_free(&error);

    r = sd_bus_call_method(bus, "org.bluez", "/org/bluez", "org.bluez.AgentManager1",
                           "RequestDefaultAgent", &error, NULL, "o", AGENT_PATH);
    if (r < 0)
        goto fail;

    printf("ready\n");
    return;

fail:
    printf("error %s\n", clean(error.message ? error.message : strerror(-r), true));
    sd_bus_error_free(&error);
}

static void set_bluez(const char *owner)
{
    free(bluez);
    bluez = owner && *owner ? strdup(owner) : NULL;
}

/* bluetoothd started, stopped or restarted: forget old requests, register again */
static int on_owner_changed(sd_bus_message *m, void *userdata, sd_bus_error *ret_error)
{
    const char *name, *old_owner, *new_owner;

    (void) userdata;
    (void) ret_error;

    if (sd_bus_message_read(m, "sss", &name, &old_owner, &new_owner) < 0)
        return 0;

    cancel_all();
    set_bluez(new_owner);
    if (bluez)
        register_agent();
    else
        printf("error bluetoothd stopped\n");
    return 0;
}

static struct request *find_request(const char *id_str)
{
    char *end;
    unsigned long id = strtoul(id_str, &end, 10);

    if (*id_str == '\0' || *end != '\0' || id == 0)
        return NULL;
    for (int i = 0; i < MAX_PENDING; i++)
        if (requests[i].kind != K_FREE && requests[i].id == id)
            return &requests[i];
    return NULL;
}

/* legacy PINs: 1-16 printable characters */
static bool valid_pin(const char *s)
{
    size_t n = strlen(s);

    if (n < 1 || n > 16)
        return false;
    for (; *s; s++)
        if (*s <= ' ' || *s >= 0x7f)
            return false;
    return true;
}

static bool parse_passkey(const char *s, uint32_t *out)
{
    char *end;
    unsigned long v;

    if (*s < '0' || *s > '9')
        return false;
    v = strtoul(s, &end, 10);
    if (*end != '\0' || v > 999999)
        return false;
    *out = (uint32_t) v;
    return true;
}

static void handle_line(char *line)
{
    char *cmd = strtok(line, " \t\r");
    char *id = cmd ? strtok(NULL, " \t\r") : NULL;
    char *arg = id ? strtok(NULL, " \t\r") : NULL;
    char *extra = arg ? strtok(NULL, " \t\r") : NULL;
    struct request *req;
    uint32_t key;

    if (!cmd)
      return; /* empty line */

    if (!strcmp(cmd, "default") && !id) {
        if (bluez)
            register_agent();
        else
            printf("error bluetoothd not running\n");
        return;
    }

    if (!id || extra || !(req = find_request(id)))
        goto bad;

    if (!strcmp(cmd, "no") && !arg)
        sd_bus_reply_method_errorf(req->msg, REJECTED, "Rejected by user");
    else if (!strcmp(cmd, "yes") && !arg &&
             (req->kind == K_CONFIRM || req->kind == K_AUTHORIZE || req->kind == K_SERVICE))
        sd_bus_reply_method_return(req->msg, NULL);
    else if (!strcmp(cmd, "pin") && arg && req->kind == K_PIN && valid_pin(arg))
        sd_bus_reply_method_return(req->msg, "s", arg);
    else if (!strcmp(cmd, "passkey") && arg && req->kind == K_PASSKEY && parse_passkey(arg, &key))
        sd_bus_reply_method_return(req->msg, "u", key);
    else
        goto bad;

    drop_request(req);
    return;

bad:
    printf("error bad input\n");
}

/* the bar went away: refuse what is still waiting, then stop.
 * this has to happen before the loop ends, because sd-bus closes
 * the connection as soon as it does */
static void quit(void)
{
    for (int i = 0; i < MAX_PENDING; i++) {
        if (requests[i].kind != K_FREE) {
            sd_bus_reply_method_errorf(requests[i].msg, REJECTED, "Agent exiting");
            drop_request(&requests[i]);
        }
    }
    sd_event_exit(event, 0);
}

static int on_stdin(sd_event_source *s, int fd, uint32_t revents, void *userdata)
{
    static char buf[512];
    static size_t len;
    char *start, *nl;
    ssize_t n;

    (void) s;
    (void) revents;
    (void) userdata;

    n = read(fd, buf + len, sizeof(buf) - len);
    if (n < 0 && (errno == EINTR || errno == EAGAIN))
        return 0;
    if (n <= 0) {
        quit();
        return 0;
    }
    len += (size_t) n;

    start = buf;
    while ((nl = memchr(start, '\n', len - (size_t) (start - buf)))) {
        *nl = '\0';
        handle_line(start);
        start = nl + 1;
    }
    len -= (size_t) (start - buf);
    memmove(buf, start, len);
    if (len == sizeof(buf))
        len = 0;   /* overlong line, drop it */
    return 0;
}

int main(void)
{
    sd_bus_error error = SD_BUS_ERROR_NULL;
    sd_bus_message *reply = NULL;
    sd_bus_slot *object = NULL, *match = NULL;
    sd_event_source *input = NULL;
    const char *owner;
    int r;

    setvbuf(stdout, NULL, _IOLBF, 0);

    if ((r = sd_event_default(&event)) < 0 ||
        (r = sd_bus_open_system(&bus)) < 0 ||
        (r = sd_bus_attach_event(bus, event, 0)) < 0 ||
        (r = sd_bus_add_object(bus, &object, AGENT_PATH, on_method, NULL)) < 0 ||
        (r = sd_bus_add_match(bus, &match,
                              "type='signal',sender='org.freedesktop.DBus',"
                              "path='/org/freedesktop/DBus',interface='org.freedesktop.DBus',"
                              "member='NameOwnerChanged',arg0='org.bluez'",
                              on_owner_changed, NULL)) < 0)
        goto fail;

    if ((r = sd_event_add_io(event, &input, STDIN_FILENO, EPOLLIN, on_stdin, NULL)) < 0) {
        fprintf(stderr, "qs-bt-agent: stdin must be a pipe or a terminal\n");
        goto fail;
    }

    /* the match is in place first, so a bluetoothd start can't slip past us */
    r = sd_bus_call_method(bus, "org.freedesktop.DBus", "/org/freedesktop/DBus",
                           "org.freedesktop.DBus", "GetNameOwner", &error, &reply, "s", "org.bluez");
    if (r >= 0 && sd_bus_message_read(reply, "s", &owner) >= 0) {
        set_bluez(owner);
        register_agent();
    } else {
        printf("error bluetoothd not running\n");
    }
    sd_bus_error_free(&error);
    sd_bus_message_unref(reply);

    r = sd_event_loop(event);

    for (int i = 0; i < MAX_PENDING; i++)
        if (requests[i].kind != K_FREE)
            drop_request(&requests[i]);

    sd_event_source_unref(input);
    sd_bus_slot_unref(match);
    sd_bus_slot_unref(object);
    sd_bus_flush_close_unref(bus);
    sd_event_unref(event);
    free(bluez);
    return r < 0 ? 1 : 0;

fail:
    fprintf(stderr, "qs-bt-agent: %s\n", strerror(-r));
    return 1;
}
