#!/bin/bash

# 判断参数个数
if [ "$#" -lt 1 ]; then
    echo "Usage: bash $0 --token [token] -p |-f [directory]"
    exit 1
fi

if [ "$1" = "--token" ]; then
    if [ "$#" -lt 3 ]; then # 检查是否提供了路径参数
        echo "Usage: bash $0 --token [token] -p |-f [directory]"
        exit 1
    fi
    
    URL="https://s.murphysec.com/vuln/maven-package-libwebp-sha1.lst"
    TOKEN="$2"
    # 请求认证 token
    AUTHORIZATION_HEADER="Authorization: Bearer $TOKEN"

    # 根据 token 下载哈希 文件
    curl -fs -H "$AUTHORIZATION_HEADER" "$URL" -o /tmp/maven-package-libwebp-sha1.lst >/dev/null 2>&1

    # 检查curl的退出状态
    if [ $? -eq 0 ]; then
        echo "File downloaded successfully."
    else
        echo "Error occurred while downloading the file."
        exit 1
    fi
fi

function check_file_hash() {
    if [ ! -n "$TOKEN" ]; then
        return 0
    fi
    local target_file="$1"
    local hash=$(sha1sum "$target_file" | awk '{print $1}')
    if grep -q "$hash" /tmp/maven-package-libwebp-sha1.lst; then
        echo "Affected file: $target_file"
        return 1
    fi
    return 0
}

PARAM_OFFSET=$(($#-1))
PARAM_LEN=$#
PARAM_VALUE=${!PARAM_LEN}

# 判断参数是-p还是-f
if [ ${PARAM_VALUE} = "-p" ]; then
    echo 'Analyzing processes...'
    # 列出当前进程打开的所有文件
    for pid in $( # 使用ps -e列出所有进程ID
        ps -e | awk '{print $1}'
    ); do
        lsof -p $pid 2>/dev/null | while read -r line; do
            file=$(echo $line | awk '{print $9}')
            # 使用 file 命令检测文件类型
            filetype=$(file "$file" 2>/dev/null)
            if echo "$filetype" | grep -q -e "ELF" -e "executable" -e "shared object" -e "shared library"; then
                # 检查文件内容
                matched_strings=$(strings "$file" | fgrep -o -e 'WebPCopyPlane' -e 'WebPCopyPixels' -e 'VP8LBuildHuffmanTable' 2>/dev/null)
                if [ ! -z "$matched_strings" ]; then
                    echo -n "Affected file: $file, Matched String: "
                    echo "$matched_strings" | tr '\n' ',' | sed 's/,$/\n/'
                fi
            fi
        done
    done
elif [ ${!PARAM_OFFSET} = "-f" ]; then
    # 递归找到所有文件并检查文件内容
    if [ "$#" -lt 2 ]; then # 检查是否提供了路径参数
        echo "Usage: $0 -f directory"
        exit 1
    fi
    
    find "$PARAM_VALUE" -type f | while read -r file; do
        # 如果是jar则解压
        case "$file" in
        *.jar | *.war | *.aar)
            check_file_hash "$file"
            
            # 解压文件并检查内容
            filetype=$(file "$file" 2>/dev/null)
            if echo "$filetype" | grep -q -e "archive data"; then
                # 解压到临时路径
                basefile=$(basename "$file")
                temp_dir=$(mktemp -d -t "${basefile}-XXXXXX")
                abs_file=$(readlink -f "$file")
                (cd $temp_dir && jar -xf "$abs_file")
                find "$temp_dir" -type f | while read -r extracted_file; do
                    filetype=$(file "$extracted_file" 2>/dev/null)
                    # 判断为可执行文件的，比对字符串
                    if echo "$filetype" | grep -q -e "ELF" -e "executable" -e "shared object" -e "shared library"; then
                        matched_strings=$(strings "$extracted_file" | fgrep -o -e 'WebPCopyPlane' -e 'WebPCopyPixels' -e 'VP8LBuildHuffmanTable' 2>/dev/null)
                        if [ ! -z "$matched_strings" ]; then
                            extracted_filepath_stripped=$(echo "$extracted_file" | sed "s|^$temp_dir||")
                            echo -n "Affected file: $file, $extracted_filepath_stripped, Matched String: "
                            echo "$matched_strings" | tr '\n' ',' | sed 's/,$/\n/'
                        fi
                    fi
                    # 判断为 jar 的，比对哈希
                    if [[ "$extracted_file" == *.jar ]]; then
                        # 获取 jar 结尾的内容并进行哈希匹配
                        check_file_hash "$inner_file"
                    fi
                done

                rm -rf "$temp_dir"
            fi

            ;;
        *.rpm)
            # 提取文件名，解压文件并检查内容
            basefile=$(basename "$file")
            temp_dir=$(mktemp -d -t "${basefile}-XXXXXX")
            # 解压 RPM 文件并检查内容
            rpm2cpio "$file" | cpio -idmv -D "$temp_dir" >/dev/null 2>&1
            find "$temp_dir" -type f | while read -r extracted_file; do
                # 使用 file 命令检测文件类型
                filetype=$(file "$extracted_file" 2>/dev/null)
                if echo "$filetype" | grep -q -e "ELF" -e "executable" -e "shared object" -e "shared library"; then
                    matched_strings=$(strings "$extracted_file" | fgrep -o -e 'WebPCopyPlane' -e 'WebPCopyPixels' -e 'VP8LBuildHuffmanTable'  2>/dev/null)
                    if [ ! -z "$matched_strings" ]; then
                        extracted_filepath_stripped=$(echo "$extracted_file" | sed "s|^$temp_dir||")
                        echo -n "Affected file: $file, $extracted_filepath_stripped, Matched String: "
                        echo "$matched_strings" | tr '\n' ',' | sed 's/,$/\n/'
                    fi
                fi
            done
            rm -rf "$temp_dir"
            ;;

        *)
            # 使用 file 命令检测文件类型
            filetype=$(file "$file" 2>/dev/null)
            if echo "$filetype" | grep -q -e "ELF" -e "executable" -e "shared object" -e "shared library"; then
                # fgrep -o -a 命令将以文本方式搜索二进制文件
                matched_strings=$(strings "$file" | fgrep -o -e 'WebPCopyPlane' -e 'WebPCopyPixels' -e 'VP8LBuildHuffmanTable' 2>/dev/null)
                if [ ! -z "$matched_strings" ]; then
                    extracted_filepath_stripped=$(echo "$extracted_file" | sed "s|^$temp_dir||")
                    echo -n "Affected file: $file, $extracted_filepath_stripped, Matched String: "
                    echo "$matched_strings" | tr '\n' ',' | sed 's/,$/\n/'
                fi

            fi
            ;;
        esac
    done
else
    echo "Invalid option: $1"
    exit 1
fi