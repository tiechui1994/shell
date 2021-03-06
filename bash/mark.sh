#!/bin/bash

#----------------------------------------------------
# File: mark.sh
# Contents: Linux当中花括号 `{}` 的使用
# Date: 19-3-17
#----------------------------------------------------

#---------------------------------------------------------------------------------------------------
# 构造序列
#
# {m..n}  m到n步长1的序列.
#
# {m..n..step} m到n步长为step的序列. step只能是正整数
#
# 注意: m>n, 则是升序序列. m<n, 则是降序序列
#
# {m..n}  笛卡儿积序列
#
#
# Bash 当中,定义一个数组的方法是在圆括号 `()` 中放置各个元素并使用空格隔开.
# month = ("Jan" "Feb" "Mar" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
# 如果需要获取数组中的元素, 就要使用括号 `[]` 并在其中填入元素的索引:
# echo ${month[3]}
#
#---------------------------------------------------------------------------------------------------

echo "升序:" {0..10}
echo "降序:" {10..0}

echo "升序,步长是2:" {0..10..2}
echo "降序,步长是2:" {10..0..2}

echo "升序:" {a..z}
echo "降序:" {z..a}

month=("Jan" "Feb" "Mar" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")
echo "元素:" ${month[4]}

#---------------------------------------------------------------------------------------------------
# 合并输出
#
# { command; command; } 将多个命令的输出内容合并到一起
#
# { pwd; ls; } // 输出内容是当前路径和当前目录内容
#
#---------------------------------------------------------------------------------------------------