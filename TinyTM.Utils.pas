unit TinyTM.Utils;

interface

uses
	Winapi.Windows;

function SysErrorMessage(ErrorCode: Cardinal; AModuleHandle: THandle = 0): string;

implementation

function SysErrorMessage(ErrorCode: Cardinal; AModuleHandle: THandle = 0): string;
var
	Buffer: PChar;
	Len: Integer;
	Flags: DWORD;
begin
	Flags := FORMAT_MESSAGE_FROM_SYSTEM or
		FORMAT_MESSAGE_IGNORE_INSERTS or
		FORMAT_MESSAGE_ARGUMENT_ARRAY or
		FORMAT_MESSAGE_ALLOCATE_BUFFER;

	if AModuleHandle <> 0 then
		Flags := Flags or FORMAT_MESSAGE_FROM_HMODULE;

	Len := FormatMessage(Flags, Pointer(AModuleHandle), ErrorCode, 0, @Buffer, 0, nil);

	try
		while (Len > 0) and ((Buffer[Len - 1] <= #32) or (Buffer[Len - 1] = '.')) do
			Dec(Len);
		SetString(Result, Buffer, Len);
	finally
		LocalFree(HLOCAL(Buffer));
	end;
end;

end.
