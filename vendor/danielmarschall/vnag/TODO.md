

Checked guideline 2026
----------------------

- Compared 2017 (wayback machine) and 2026 [Plugin Development Guidelines](https://nagios-plugins.org/doc/guidelines.html)
  * (REMOVED) performance data: value, min and max in class `[-0-9.]`. Must all be the same UOM
  * (REMOVED) value may be a literal "U" instead, this would indicate that the actual value couldn't be determined -- but it is still allowed?
  * (REMOVED) KB, MB, TB, ... us, ms... -- but is it still allowed?
- For plugins with more than one type of threshold (unsure: Does this mean you must implement all forms, or just one of them?)
  * Use long options like --critical-time
  * Use repeated options: check_load -w 10 -w 6 -w 4 -c 16 -c 10 -c 10
  * Use comma-separated values: check_load -w 10,6,4 -c 16,10,10
  * Express ranges with colons: check_procs -C httpd -w 1:20 -c 1:30
  * Express lists with commas: -p 1000,1010,1050:1060,2000
- Check if we support this: Don't use exec(), popen(), etc. to execute external commands without explicitly using the full path. This makes the plugin vulnerable to hijacking by a trojan horse earlier in the search path. Use spopen() for External Commands. If you have to execute external commands from within your plugin and you're writing it in C, use the spopen() function. The code for spopen() and spclose() is included with the core plugin distribution.

TODO
----

- allow changing automatic help page to describe which individual ranges stand for (is it already possible, by getting the argument object and then changing its help text?)
- everywhere getter and setter instead of accessing class member variables
- ipfm monitor: dygraph has MIT license
- *.conf files: /daten sollte nicht in den example conf's stehen. irgendwie anders machen (Aber achtung: wir symlinken die config files in unserem /etc )
- idea: a script that converts the output of an EXISTING nagios plugin into VNag Weboutput. So an arbitary Nagios script can be forwarded to other systems over HTTP
- make all plugins "web enabled"
- In the framework create an easy function, which generates a simple default HTML header and footer
- should error details, e.g. defective hard disks at the mdstat monitor be Verbosity=Summary, or Verbosity=AdditionalInformation ?
- idea for a new plugin: sudo /daten/scripts/tools/check_etc_perms | grep -v "world readable" | grep -v "world executable"
- should putputID, passwordOut and privateKey be a default argument? Then you can use encryption/signing for all plugins by default
- In re syntax checking/getopt:
  * Evaluate if PHP 7.1 (with getopt()'s $optind) is able to detect unexpected CLI parameters for us (so we can output a syntax warning)
  * Limit warning range numbers (avoid user adds too many, e.g. "-w A,B,C" although only 2 are allowed)

Future
------

- For arguments (warning/critical), also accept mixed UOMs, e.g. MB and %
- In re usage page:
  * Automatic creation of usage page. Which arguments are necessary?
  * Automatically generate syntax?
- Allow individual design via CSS
- Check if regex of validateLongOpt() is accurate

Unsure
------

- Automatically encrypt/sign via a global config setting?
