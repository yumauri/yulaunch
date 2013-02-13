unit reghandlers;

{$mode objfpc}

interface

uses
	Classes, Windows, IniFiles, Registry;

procedure createHandlers(inifile: TIniFile; programName: string);
procedure deleteHandlers(inifile: TIniFile);

implementation

// register protocols in windows registry
// http://msdn.microsoft.com/en-us/library/aa767914(VS.85).aspx
// .../operaprefs.ini -> [Trusted Protocols]
procedure createHandlers(inifile: TIniFile; programName: string);
var
	i: integer;
	reg: TRegistry;
	protocols: TStrings;
	error: boolean;
begin
	protocols := TStringList.Create;
	inifile.ReadSections(protocols);

	reg := TRegistry.Create;
	reg.RootKey := HKEY_CLASSES_ROOT;

	error := false;
	for i := 0 to protocols.Count - 1 do begin
		// if key already exists -> remove it
		if reg.KeyExists(protocols[i]) then
			reg.DeleteKey(protocols[i]);

		// create and register protocol
		//reg.Access := KEY_WRITE;
		if reg.OpenKey(protocols[i], true) then begin
			reg.WriteString('', 'URL:Telnet Protocol');
			reg.WriteInteger('EditFlags', 2);
			reg.WriteString('FriendlyTypeName', '@ieframe.dll,-907');
			reg.WriteString('URL Protocol', '');
			reg.WriteInteger('BrowserFlags', 8);

			if reg.OpenKey('DefaultIcon', true) then
				reg.WriteString('', programName + ',0')
			else begin
				error := true;
				break;
			end;
			reg.CloseKey();

			if reg.OpenKey(protocols[i] + '\\shell', true) then
				reg.WriteString('', '')
			else begin
				error := true;
				break;
			end;
			reg.CloseKey();

			if reg.OpenKey('open\\command', true) then
				reg.WriteString('', programName + ' "%1"')
			else begin
				error := true;
				break;
			end;
			reg.CloseKey();

		end
		else begin
			error := true;
			break;
		end;
		reg.CloseKey();
	end;

	if error then begin
		// echo('ERROR: can''t write registry key');
		// halt(ERROR_WRITE_FAULT);
	end;
	
	reg.Free;
	protocols.Free;
end;

// remove protocols from windows registy
procedure deleteHandlers(inifile: TIniFile);
var
	i: integer;
	reg: TRegistry;
	protocols: TStrings;
begin
	protocols := TStringList.Create;
	inifile.ReadSections(protocols);

	reg := TRegistry.Create;
	reg.RootKey := HKEY_CLASSES_ROOT;

	for i := 0 to protocols.Count-1 do begin
		// if key already exists -> remove it
		if reg.KeyExists(protocols[i]) then
			reg.DeleteKey(protocols[i]);
		reg.CloseKey();
	end;

	reg.Free;
	protocols.Free;
end;

end.