By default, configuration file are looked up near to binary yulaunch. And, if it cannot be found ­there – it will be looked up inside default setting path for your operation system (by default, it is _C:\Documents and Settings\user\Local Settings\Application Data\yulaunch\yulaunch.cfg_ for Windows, and _/home/user/.config/yulaunch.cfg_ for Linux).

# Introduction #

Configuration file by format ­- it is a simple INI file. It has sections ­- one section per one protocol. Minimally required property is "command" for each section.
```
[ssh]
command = putty.exe "%1"

[telnet]
command = putty.exe -telnet "%1"
```

# Details #

You can specify a little more properties for protocol, here they are:

### spacer ###
If you program requires more than one parameter, you can use separator in the link, for example, if you need port in addition to server address, you can setup protocol as
```
[ssh]
command = putty.exe -P %2 "%1"
spacer = |
```
and use link ssh://127.0.0.1|2202

As you can see, you can use %1, %2 etc to access to the parts, separated by delimeter. Also, you can use variable names
```
[ssh]
command = putty.exe -P %port "%1"
spacer = |
```
and use link ssh://127.0.0.1|port=2202

In last example variables will be:<br>
<blockquote>%1 → 127.0.0.1<br>
%2 → port=2202<br>
%port → 2202</blockquote>

<h3>cond</h3>
Intricate property, with which you can define complicated behavior of the tool, if you want to use different external programs for one protocol, or if you want use different program parameters with different links for single protocol.<br>
<br>
Main idea is that you can define term, which will check presence or absence of variable inside your link.<br>
<br>
For example, if you have two types of links:<br>
<blockquote>ssh://127.0.0.1/<br>
ssh://127.0.0.1|port=2202/</blockquote>

you can use them with term:<br>
<pre><code>[ssh]<br>
command = putty.exe "%1"<br>
spacer = |<br>
cond = %port @portcommand<br>
portcommand = putty.exe -P %port "%1"<br>
</code></pre>
Tool will check, if there is %port variable inside link → then instead of default "command" will be used "portcommand".<br>
<br>
You can define complicated term using boolean operators & (and), | (or), ! (not).<br>
<br>
<u>Note!</u> Term should be in <a href='http://en.wikipedia.org/wiki/Reverse_Polish_notation'>reverse polish notation</a>.<br> For example, if you want check two variables by logical condition <b>%var1 & %var2</b>, you should write <b>%var1 %var2 &</b>

Term will be parsed until it meet first @command with "true" result.<br>
<br>
Complicated example<br>
<pre><code>cond = %vds @sshv %pass @ispds %login %vds ! &amp; %name | @tstcomm<br>
</code></pre>
It means: if there is %vds variable → returns command @sshv, then, if there is variable %pass → returns command @ispds, then, if there is variable %login, but there isn't variable %vds, or there is variable %name → returns command @tstcomm.<br>
<br>
This condition in normal notation looks like:<br>
<pre><code>cond = %vds ? @sshv : (%pass ? @ispds : ((%login &amp; !%vds) | %name ? @tstcomm : @command))<br>
</code></pre>
(you cannot write this, it is just explanation)