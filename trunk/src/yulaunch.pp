(*
 * URL launcher for Opera
 * Idea from "URL Protocol Launcher" (C) Erik Rainey
 * http://blog.erik.rainey.name/2006/01/31/url-protocol-launcher ( page is unavailable now :( )
 *
 * Source and documentation at: http://code.google.com/p/yulaunch/
 * 
 * Version 0.9a
 * Author Didenko Victor
 *
 * Released under the MIT license
 *
 * Copyright (C) 2013 Didenko Victor
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software
 * is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 * IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *)

{$MODE objfpc}
{$H+}

{$IFDEF Windows}
	{$APPTYPE GUI}
{$ENDIF}

program yulaunch;

uses
	bstack,
	{$IFDEF Windows}
	reghandlers,
	Windows,
	{$ENDIF}
	SysUtils, IniFiles, Classes, Process;

const
	NO_ERROR = 0;
	ERROR_INVALID_PARAMETER = 87;
	ERROR_BAD_FORMAT = 11;
	ERROR_PATH_NOT_FOUND = 3;
	ERROR_FILE_NOT_FOUND = 2;

var
	debug: boolean = false;


// convert url encoded string to utf8 string
function URLDecode(const s: string): string;
var
	sAnsi: string;
	sUtf8: string;
	sWide: WideString;
	i: cardinal = 1;
	len: cardinal = 1;
	ESC: string[2];
	CharCode: integer;
	c: char;
begin
	sAnsi := PChar(s);
	SetLength(sUtf8, length(sAnsi));
	while (i <= cardinal(length(sAnsi))) do begin
		if (sAnsi[i] <> '%') then begin
			if (sAnsi[i] = '+') then
				c := ' '
			else
				c := sAnsi[i];
			sUtf8[len] := c;
			inc(len);
		end else begin
			inc(i);
			ESC := Copy(sAnsi, i, 2);
			inc(i, 1);
			try
				CharCode := StrToInt('$' + ESC);
				c := char(CharCode);
				sUtf8[len] := c;
				inc(len);
			except
			end;
		end;
		inc(i);
	end;
	dec(len);
	SetLength(sUtf8, len);

	sWide := UTF8Decode(sUtf8);
	len := length(sWide);

	result := sWide;
end;

// show message
procedure echo(const str: string);
{$IFDEF Unix}
var
	i: integer;
	len: integer;
{$ENDIF}
begin
	{$IFDEF Windows}
	MessageBoxA(0, PAnsiChar(str), 'YuLauncher', MB_OK);
	{$ENDIF}
	{$IFDEF Unix}
	//TODO
	len := length(str);
	for i := 1 to len do
		if str[i] = #13 then
			writeln()
		else
			write(str[i]);
	writeln();
	writeln();
	{$ENDIF}
end;

// show message end exit program
procedure error(const str: string; const errCode: integer);
begin
	echo('ERROR: ' + str);
	halt(errCode);
end;

// parse condition
{
- condition defined in 'conf' row in configuration file
- parsing continues until first command found
- in conditions there are checks for presence or absence of variables
- if there is no suitable command found -> returns command by default
- spaces delimeters required!
- boolean operators allowed -> & (and), | (or), ! (not)
- condition should be in reverse polish notation
- prefix % for variables, prefix @ for commands

e.g.:
	cond = %vds @sshv %pass @ispds %login %vds ! & %name | @tstcomm
	->	if there is 'vds' variable -> returns command 'sshv'
		then, if there is variable 'pass' -> returns command 'ispds'
		then, if there is variable 'login', but there isn't variable 'vds',
		or there is variable 'name' -> returns command 'tstcomm'

this condition in normal notation looks like:
	cond = %vds ? @sshv : (%pass ? @ispds : ((%login & !%vds) | %name ? @tstcomm : @command))
}
function getCondResult(const cond: string; const args: TStringList): string;
var
	i: integer;
	st: TBStack;
	condlist: TStringList;
	item: string;
begin
	st := TBStack.Create();
	condlist := TStringList.Create();
	condlist.Delimiter := ' ';
	condlist.DelimitedText := cond;

	try
		for i := 0 to condlist.Count - 1 do begin
			item := condlist[i];
			if item[1] = '%' then begin
				delete(item, 1, 1);
				if args.Values[item] <> '' then
					st.push(true)
				else
					st.push(false);
			end else
			if item[1] = '@' then begin
				if st.pop then begin
					delete(item, 1, 1);
					if debug then
						echo('condition command found: ' + item);
					result := item;
					exit;
				end;
			end else
			if item = '&' then
				st.push(st.pop and st.pop)
			else
			if item = '|' then
				st.push(st.pop or st.pop)
			else
			if item = '!' then
				st.push(not st.pop)
			else
				error('error in condition parsing - unknown item', ERROR_BAD_FORMAT);
		end;
	except
		error('error in condition parsing - exception while parsing', ERROR_BAD_FORMAT);
	end;

	st.Free;
	condlist.Free;

	if debug then
		echo('condition command not found, use default');
	result := 'command';
end;

// get execution command from configuration file
function getLaunchCommand(const iniFile: TIniFile; const protocol: string; const args: TStringList): string;
var
	cond: string;
	command: string;
begin
	// get command from configuration file, by protocol
	command := iniFile.ReadString(protocol, 'command', '');
	if debug then
		echo('handler:' + #13 + command);
	if command = '' then
		error('handler not found', ERROR_PATH_NOT_FOUND);

	// get conditions and command by them
	cond := iniFile.ReadString(protocol, 'cond', '');
	if cond <> '' then begin
		if debug then
			echo('condition found:' + #13 + cond);
		cond := getCondResult(cond, args);
		command := iniFile.ReadString(protocol, cond, command);
	end;

	result := command;
end;

// execute command
procedure exec(command: string; const args: TStringList; const dir: string);
var
	i: integer;
	proc: TProcess;
begin
	// replace variables in command
	if debug then
		echo('command before:' + #13 + command);
	for i := 0 to args.Count - 1 do
		command := StringReplace(command, '%' + args.Names[i], args.Values[args.Names[i]], [rfReplaceAll]);
	if debug then
		echo('command after:' + #13 + command);

	// set current directory
	ChDir(dir);

	// execute external program
	proc := TProcess.Create(nil);
	try
		proc.CommandLine := command; // <-- deprecated
		//TODO rework to
		// proc.Executable := '...';
		// proc.Parameters.Add('...');
		proc.Execute;
	finally
		proc.Free;
	end;
end;

// generate list of variables in command
function generateArgsList(const url: string; const spacer: char): TStringList;
var
	i: integer;
	epos: integer;
	ret: TStringList;
begin
	ret := TStringList.Create();

	if spacer <> #0 then begin
		ret.Delimiter := spacer;
		ret.DelimitedText := url;
		for i := 0 to ret.Count - 1 do begin
			epos := Pos('=', ret[i]);
			if epos = 0 then
				ret[i] := IntToStr(i + 1) + '=' + ret[i]
			else
				ret.Add(IntToStr(i + 1) + '=' + ret[i]); //copy(ret[i], epos + 1, length(ret[i]) - epos));
		end;
	end else
		ret.Add('1=' + url);

	result := ret;
end;

// get path to config file
function getCfgFile(const fileName: string): TIniFile;
var
	path: string;
begin
	// try to get config file from directory with binary
	path := fileName;
	{$IFDEF Windows}
	delete(path, length(path) - 2, 3); // remove .exe
	path := path + 'cfg';
	{$ENDIF}
	{$IFDEF Unix}
	path := path + '.cfg';
	{$ENDIF}

	if FileExists(path) then begin
		if debug then
			echo('cfg file:' + #13 + path);
	end else begin
		if debug then
			echo('cfg file:' + #13 + path + #13 + 'doesn''t exists');

		// try to get config file from config place
		path := GetAppConfigFile(false);
		if FileExists(path) then begin
			if debug then
				echo('cfg file:' + #13 + path);
		end else begin
			if debug then
				echo('cfg file:' + #13 + path + #13 + 'doesn''t exists');
			error('can''t find configuration file', ERROR_FILE_NOT_FOUND);
		end;
	end;

	result := TIniFile.Create(path);
end;

// main
var
	myFileName: string;
	i: integer;
	argc: integer;
	argv: string;
	url: string;
	iniFile: TIniFile;
	protocol: string = '';
	spacer: char = #0;
	args: TStringList;
	command: string;
	{$IFDEF Windows}
	registerHandlers: boolean = false;
	unregisterHandlers: boolean = false;
	{$ENDIF}

begin
	myFileName := ParamStr(0);

	// parse parameters
	argc := ParamCount;
	if argc = 0 then
		error('don''t start without parameters', NO_ERROR);

	for i := 1 to argc do begin
		argv := ParamStr(i);
		if (argv = '-d') or (argv = '--debug') then begin
			debug := true;
			echo('debug enabled');
		end else
		if (copy(argv, 1, 2) = '-s') and (length(argv) = 3) then begin
			spacer := argv[3];
			if debug then
				echo('spacer: ' + spacer);
		end else
			url := argv;

		{$IFDEF Windows}
		if argv = '--register' then
			registerHandlers := true
		else
		if argv = '--unregister' then
			unregisterHandlers := true;
		{$ENDIF}
	end;

	if url = '' then
		error('command not found', ERROR_INVALID_PARAMETER);
	url := URLDecode(url);

	// initialize config file
	iniFile := getCfgFile(myFileName);

	{$IFDEF Windows}
	// register/unregister handlers and exit
	if registerHandlers then begin
		if debug then
			echo('register handlers in registry');
		createHandlers(iniFile, myFileName);
		halt(NO_ERROR);
	end else
	if unregisterHandlers then begin
		if debug then
			echo('remove handlers from registry');
		deleteHandlers(iniFile);
		halt(NO_ERROR);
	end;
	{$ENDIF}

	// get protocol and arguments
	// e.g. ssh://127.0.0.1
	protocol := copy(url, 1, pos(':', url) - 1); // get all before ':'
	delete(url, 1, length(protocol) + 1);
	while url[1] = '/' do // remove all leading slashes '/'
		delete(url, 1, 1);
	if url[length(url)] = '/' then // remove trailing slash '/'
		SetLength(url, length(url) - 1);

	if protocol = '' then
		error('command doesn''t valid', ERROR_INVALID_PARAMETER);

	// if spacer doesn't specified -> try to get it from configuration file
	if spacer = #0 then
		if iniFile.ValueExists(protocol, 'spacer') then begin
			spacer := iniFile.ReadString(protocol, 'spacer', ' ')[1];
		if debug then
			echo('spacer from cfg file: ' + spacer);
	end;

	// create hash with all variables
	args := generateArgsList(url, spacer);
	if debug then
		echo('protocol: ' + protocol + #13 + 'url: ' + url + #13#13 + args.Text);

	// get commant to execute and execute it
	command := getLaunchCommand(iniFile, protocol, args);
	exec(command, args, ExtractFilePath(myFileName));

	args.Free;
	iniFile.Free;
end.
