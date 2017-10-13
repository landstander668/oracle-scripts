# BASH scripts

Please note that these scripts don't shy away from Bash-specific syntax, since those capabilities often make scripts simpler to write and maintain... plus, at this point I've found Bash to be ubiquitous for a number of years. While they may well work under similarly capable shells such as Ksh and Zsh, breakage is most definitely expected when using standard /bin/sh implementations.

### dbping

This gives timing information similar to the Oracle *tnsping* utility, which is often unavailable since it isn't included in the Instant Client. The primary difference is that it attempts database authentication using SQL*Plus (which is expected to always fail, although the functionality doesn't depend upon this), whereas tnsping stops at the listener and never touches the DB itself. So it's a more thorough connectivity test, which is expected to return somewhat longer times.

Usage:

```
dbping connection_string [count]
```
The first parameter is required, and can be any connection identifier which SQL*Plus is able to interpret... typically a tnsnames entry or EZConnect string. The second, optional, parameter is an integer in the range of 1-20, and indicates how many times the test should be performed.

### upload_to_MOS

This uploads one or more diagnostic files to a specified Service Request on My Oracle Support (MOS), using the HTTPS protocol. This process is documented in Doc ID 1682567.1 on the MOS website.

Usage:
```
upload_to_MOS file1 [[file2]...] sr_number
```
This requires a minimum of two parameters, with all leading parameters indicating files to be uploaded. The final parameter is the target SR number for the upload data.

Your MOS username can be set either by updating the "mos_account=" line near the top of the script, or setting the *MOS_ACCOUNT* environment (which will override the former). The script will prompt for your MOS password, when is then provided to cURL once per file being upload. This value is not saved, or used in any other manner.
