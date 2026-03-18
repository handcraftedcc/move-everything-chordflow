#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "host/midi_fx_api_v1.h"
#include "host/plugin_api_v1.h"

extern midi_fx_api_v1_t* move_midi_fx_init(const host_api_v1_t *host);

static void fail(const char *msg) {
    fprintf(stderr, "FAIL: %s\n", msg);
    exit(1);
}

static int send_msg(midi_fx_api_v1_t *api, void *inst, uint8_t status, uint8_t note, uint8_t vel) {
    uint8_t in[3] = { status, note, vel };
    uint8_t out_msgs[16][3];
    int out_lens[16];
    return api->process_midi(inst, in, 3, out_msgs, out_lens, 16);
}

int main(void) {
    host_api_v1_t host;
    midi_fx_api_v1_t *api;
    void *inst;
    int out;

    memset(&host, 0, sizeof(host));
    host.api_version = MOVE_PLUGIN_API_VERSION;

    api = move_midi_fx_init(&host);
    if (!api || !api->create_instance || !api->destroy_instance || !api->process_midi) {
        fail("API callbacks missing");
    }

    inst = api->create_instance(".", NULL);
    if (!inst) fail("create_instance failed");

    out = send_msg(api, inst, 0x90, 60, 100);
    if (out <= 0) fail("first note_on produced no output");

    out = send_msg(api, inst, 0x90, 60, 100);
    if (out <= 0) fail("second note_on produced no output");

    /* Loop-boundary ordering case: stale note_off from previous note instance. */
    out = send_msg(api, inst, 0x80, 60, 0);
    if (out != 0) fail("stale note_off should be ignored");

    out = send_msg(api, inst, 0x80, 60, 0);
    if (out <= 0) fail("current note_off should release active chord");

    api->destroy_instance(inst);
    printf("PASS: chordflow note boundary ordering\n");
    return 0;
}
