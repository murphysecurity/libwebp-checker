中文 | [EN](README.md)

# 针对CVE-2023-4863漏洞的libwebp检查工具

用于在命令行检测指定目录或当前运行进程中是否存在大于0.5.0版本的libwebp依赖。
温馨提示：请尽量在测试环境中运行，以免影响生产服务。

<p>
  <a href="https://www.oscs1024.com/cd/1522831757949284352">
    <img src="https://www.oscs1024.com/platform/badge/murphysecurity/murphysec.svg">
  </a>

  <a href="https://github.com/murphysecurity/murphysec">
    <img src="https://badgen.net/badge/Github/murphysecurity/21D789?icon=github">
  </a>

<img src="https://img.shields.io/github/go-mod/go-version/murphysecurity/murphysec.svg?style=flat-square">
  <a href="https://github.com/murphysecurity/murphysec/blob/master/LICENSE">
    <img alt="GitHub" src="https://img.shields.io/github/license/murphysecurity/murphysec?style=flat-square">
  </a>
  <img alt="GitHub last commit" src="https://img.shields.io/github/last-commit/murphysecurity/murphysec?style=flat-square">
  <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/murphysecurity/murphysec?style=social">
  </p>

### 效果截图

运行结果

  <img alt="scan result" src="./assets/scan-process-result.png" width="80%">


  <img alt="scan result" src="./assets/scan-path-result.png" width="80%">
  


## 目录

1. [工作原理](#工作原理)
2. [使用场景](#使用场景)
3. [使用步骤](#使用步骤)
4. [交流和问题反馈](#交流和问题反馈)
5. [开源协议](#开源协议)

## 工作原理

通过扫描libwebp 0.5.0 版本及以后新增的关键字字符串进行匹配发现直接依赖、间接依赖。

## 使用场景

在本地或服务器环境中，针对指定路径、所有运行的进程中的二进制文件、jar包和rpm包，检测是否存在libwebp的漏洞组件依赖。

## 使用步骤

### 1. 获取访问令牌

> 工具需要使用墨菲安全账户的`访问令牌`进行认证才能正常使用。[访问令牌是什么？（点击查看详情）](https://www.murphysec.com/docs/faqs/project-management/access-token.html)

进入[墨菲安全控制台](https://www.murphysec.com/console)，点击`设置` - `访问令牌`

<img alt="scan result" src="./assets/access-token.png" width="80%">


### 2. 执行扫描

#### 扫描指定路径

```
bash libwebp-scan-tools.sh --token Your_Token_From_Console -f /path_you_want_scan/
```

#### 扫描当前服务器的所有进程文件

```
bash libwebp-scan-tools.sh --token Your_Token_From_Console -p
```


### 3. 查看结果 

命令行会打印受影响的文件名、进程 ID 以及匹配到的字符串关键字，如`WebPCopyPlane,WebPCopyPlane`。便于后续开展针对性的推进修复。

## 交流和问题反馈

联系并添加运营微信号，拉您进墨菲安全交流微信群

<img src="./assets/wechat.png" width="200px">

## 开源协议
[Apache 2.0](LICENSE)