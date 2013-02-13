(*
 * Simple stack of boolean values
 *)

{$mode objfpc}

unit bstack;

interface

uses
	sysutils;

type
	EEmptyStack = class(Exception);

	TBStack = class
	private
		items: array of boolean;
	public
		procedure push(item: boolean);
		function pop(): boolean;
		function getCount(): integer;
		property count: integer read getCount;
	end;

implementation

// get stack elements count
function TBStack.getCount(): integer;
begin
	result := length(items);
end;

// put element to stack
procedure TBStack.push(item: boolean);
var c: integer;
begin
	c := count + 1;
	SetLength(items, c);
	items[c-1] := item;
end;

// get element from stack
function TBStack.pop(): boolean;
var c: integer;
begin
	c := count;
	if c = 0 then
		raise EEmptyStack.Create('Stack is empty');
	result := items[c-1];
	SetLength(items, c-1);
end;

end.