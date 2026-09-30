/* Fake agent for the herdr harness: named `claude` so herdr detects a Claude
 * pane, but it only sleeps, so it never talks to the API. A compiled binary is
 * needed: a copied /bin/sleep is killed by macOS (code signature). */
#include <unistd.h>
int main(void) { for (;;) pause(); }
