# misc-cli.sh aliases sed→sd; profile.lsf needs real sed (backtick pipelines).
unalias sed 2>/dev/null
source /tool/lsf/conf/profile.lsf
source /etc/profile.d/modules.sh
