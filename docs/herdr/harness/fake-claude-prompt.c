/* Fake agent for the herdr harness that shows a Claude Code permission prompt,
 * which herdr's claude.toml manifest reports as `blocked`. SIGUSR1 clears the
 * prompt, which is what approving it looks like to herdr. */
#include <signal.h>
#include <stdio.h>
#include <unistd.h>

static void approved(int sig) {
	(void)sig;
	printf("\033[2J\033[H  Running...\n");
	fflush(stdout);
}

int main(void) {
	signal(SIGUSR1, approved);
	printf("\033[2J\033[H Bash command\n\n   npm run migrate\n   Run staging migration\n\n"
	       " Do you want to proceed?\n \xe2\x9d\xaf 1. Yes\n   2. Yes, and don't ask again\n"
	       "   3. No\n\n Esc to cancel\n");
	fflush(stdout);
	for (;;) pause();
}
