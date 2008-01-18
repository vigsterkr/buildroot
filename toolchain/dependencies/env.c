/* print the current environment to track eventually changed settings.
 *
 * Copyright (C) 2008 Bernhard Fischer
 *
 * Licensed under GPLv2 or later, see
 *   http://www.gnu.org/licenses/gpl.txt
 */
#include <unistd.h>
extern char **environ;
int main(void)
{
	char **envp;
	int ret = 0;
	for (envp = environ; *envp; envp++) {
		if (envp[0][0] == '_' && envp[0][1] == '=')
			continue; /* Skip last command */
		if (puts(*envp) <= 0) {
			ret = 1;
			break;
		}
	}
	return ret;
}
