unit TinyTM.Menu;

interface

uses
	Winapi.Windows,
	Winapi.ShellAPI,
	TinyTM.Utils;

type
	TNotifyMenuItemAdded = procedure(MenuItem: Pointer) of object;

	TRadio = record
		First: Integer;
		Last: Integer;
		Checked: NativeUInt;
		IsRadio: Boolean;
	end;

	PMenuItem = ^TMenuItem;

	TMenuItem = record
	private
		FParent: PMenuItem;
		FList: array of Pointer;
		FHandle: HMENU;
		//
		FCaption: string;
		FUniqueID: Integer;
		FPosition: Integer;
		FRadio: TRadio;
		FOnItemAdd: TNotifyMenuItemAdded;
		//
		procedure SetCaption(const Value: string);
		procedure SetHandle(const Value: HMENU);
		procedure SetChecked(const Value: Boolean);
		function GetHandle: HMENU;
		function GetChecked: Boolean;
		function GetCount: Integer;
		function GetItem(Index: Integer): PMenuItem;
		function GetCaption: string;
		function GetUniqueID: Integer;
		procedure SetUniqueID(const Value: Integer);
		function GetParent: PMenuItem;
		procedure SetParent(const Value: PMenuItem);
		function GetItemState: TMenuItemInfo;
		function GetEnabled: Boolean;
		procedure SetEnabled(const Value: Boolean);
		function GetOnItemAdd: TNotifyMenuItemAdded;
		procedure SetOnItemAdd(const Value: TNotifyMenuItemAdded);
		function GetPosition: Integer;
	public
		//
		procedure Init;
		procedure Free;
		//
		procedure Clear;
		procedure DeleteItem(Index: Integer);
		function Add(Caption: string; ID: Integer): PMenuItem; overload;
		//
		procedure Check;
		procedure Uncheck;
		procedure ToggleCheck;
		//
		procedure Enable;
		procedure Disable;
		procedure ToggleEnable;
		//
		function IsRadioItem: Boolean;
		procedure CheckRadio;
		//
		property Items[Index: Integer]: PMenuItem read GetItem; default;
		property Count: Integer read GetCount;
		property Caption: string read GetCaption write SetCaption;
		property Handle: HMENU read GetHandle write SetHandle;
		property Parent: PMenuItem read GetParent write SetParent;
		property Checked: Boolean read GetChecked write SetChecked;
		property Enabled: Boolean read GetEnabled write SetEnabled;
		property UniqueID: Integer read GetUniqueID write SetUniqueID;
		property OnItemAdd: TNotifyMenuItemAdded read GetOnItemAdd write SetOnItemAdd;
		property Radio: TRadio read FRadio;
		property Position: Integer read GetPosition;
	end;

implementation

const
	TM_SEPARATOR = '-';
	TM_CHECKED = '^';
	TM_DISABLED = '~';
	TM_BREAK = '`';
	TM_RADIO = '*';

	{ TMenuItem }

procedure TMenuItem.DeleteItem(Index: Integer);
var
	i, L: Integer;
begin
	DestroyMenu(TMenuItem(FList[Index]^).FHandle);
	TMenuItem(FList[Index]^).Free;
	Dispose(PMenuItem(FList[Index]));
	L := Length(FList);
	for i := Index + 1 to L - 1 do
		FList[i - 1] := FList[i];
	SetLength(FList, L - 1);
end;

function TMenuItem.GetCaption: string;
begin
	Result := FCaption;
end;

function TMenuItem.GetChecked: Boolean;
begin
	Result := ((GetItemState.fState and MFS_CHECKED) = 0) and not(IsRadioItem);
end;

function TMenuItem.GetCount: Integer;
begin
	Result := Length(FList);
end;

function TMenuItem.GetEnabled: Boolean;
begin
	Result := (GetItemState.fState and MFS_ENABLED) = 0;
end;

function TMenuItem.GetHandle: HMENU;
begin
	Result := FHandle;
end;

function TMenuItem.GetItem(Index: Integer): PMenuItem;
begin
	Result := FList[Index];
end;

function TMenuItem.GetItemState: TMenuItemInfo;
var
	Item: TMenuItemInfo;
begin
	Item.cbSize := SizeOf(MENUITEMINFO);
	Item.fMask := MIIM_STATE;

	if not GetMenuItemInfo(FParent.Handle, FUniqueID, False, Item) then
	begin
		MessageBox(0, PChar(TinyTM.Utils.SysErrorMessage(GetLastError)), 'Error', MB_OK + MB_ICONSTOP);
		Halt(0);
	end;
	Result := Item;
end;

function TMenuItem.GetOnItemAdd: TNotifyMenuItemAdded;
begin
	Result := FOnItemAdd;
end;

function TMenuItem.GetParent: PMenuItem;
begin
	Result := FParent;
end;

function TMenuItem.GetPosition: Integer;
begin
	Result := FPosition;
end;

function TMenuItem.GetUniqueID: Integer;
begin
	Result := FUniqueID;
end;

procedure TMenuItem.Init;
begin
	FHandle := CreatePopupMenu;
	FParent := nil;
	FCaption := '';
	FUniqueID := -1;
	FPosition := -1;
	FOnItemAdd := nil;
	FRadio.First := -1;
	FRadio.Last := -1;
	FRadio.Checked := NativeUInt(-1);
end;

function TMenuItem.IsRadioItem: Boolean;
begin
	Result := Parent.Radio.IsRadio;
end;

procedure TMenuItem.SetCaption(const Value: string);
begin
	FCaption := Value;
end;

procedure TMenuItem.SetChecked(const Value: Boolean);
var
	Info: TMenuItemInfo;
begin
	Info := GetItemState;
	Info.fState := Info.fState or MFS_CHECKED;
	SetMenuItemInfo(FParent.Handle, FUniqueID, False, Info);
end;

procedure TMenuItem.SetEnabled(const Value: Boolean);
var
	Info: TMenuItemInfo;
begin
	Info := GetItemState;
	Info.fState := Info.fState or MFS_ENABLED;
	SetMenuItemInfo(FParent.Handle, FUniqueID, False, Info);
end;

procedure TMenuItem.SetHandle(const Value: HMENU);
begin
	FHandle := Value;
end;

procedure TMenuItem.SetOnItemAdd(const Value: TNotifyMenuItemAdded);
begin
	FOnItemAdd := Value;
end;

procedure TMenuItem.SetParent(const Value: PMenuItem);
begin
	FParent := Value;
end;

procedure TMenuItem.SetUniqueID(const Value: Integer);
begin
	FUniqueID := Value;
end;

procedure TMenuItem.Check;
begin
	if (not IsRadioItem) then
		CheckMenuItem(FParent.FHandle, FUniqueID, MF_CHECKED);
end;

procedure TMenuItem.CheckRadio;
begin
	CheckMenuRadioItem(Parent.FHandle, Parent.FRadio.First, Parent.FRadio.Last, FPosition, MF_BYPOSITION);
end;

procedure TMenuItem.Uncheck;
begin
	if (not IsRadioItem) then
		CheckMenuItem(FParent.FHandle, FUniqueID, MF_UNCHECKED);
end;

procedure TMenuItem.ToggleCheck;
begin
	if Checked then
		Check
	else
		Uncheck;
end;

procedure TMenuItem.Enable;
begin
	EnableMenuItem(FParent.FHandle, FUniqueID, MF_ENABLED);
end;

procedure TMenuItem.Free;
begin
	Clear;
end;

procedure TMenuItem.Disable;
begin
	EnableMenuItem(FParent.FHandle, FUniqueID, MF_DISABLED);
end;

procedure TMenuItem.ToggleEnable;
begin
	if Enabled then
		Disable
	else
		Enable;
end;

procedure TMenuItem.Clear;
var
	i: Integer;
begin
	for i := 0 to GetCount - 1 do
		DeleteItem(0);
end;

function TMenuItem.Add(Caption: string; ID: Integer): PMenuItem;
var
	Flag: UINT;
begin
	New(Result);
	Result.Init;
	Result.Caption := Caption;
	Result.FUniqueID := ID;
	Result.FParent := @Self;
	Result.OnItemAdd := FOnItemAdd;

	SetLength(FList, Length(FList) + 1);
	FList[Length(FList) - 1] := Result;
	Result.FPosition := High(FList);

	Flag := MF_STRING;

	if (Length(Caption) > 0) then
	begin
		if (Result.FCaption = TM_SEPARATOR) then
			Flag := MF_SEPARATOR
		else
		begin
			if (Result.FCaption[1] = TM_CHECKED) then
			begin
				Flag := Flag or MF_CHECKED;
				Delete(Result.FCaption, 1, 1);
			end
			else if (Result.FCaption[1] = TM_DISABLED) then
			begin
				Flag := Flag or MF_DISABLED;
				Delete(Result.FCaption, 1, 1);
			end
			else if (Result.FCaption[1] = TM_BREAK) then
			begin
				Flag := Flag or MF_MENUBREAK;
				Delete(Result.FCaption, 1, 1);
			end
			else if (Result.FCaption[1] = TM_RADIO) then
			begin
				FRadio.IsRadio := True;

				if (FRadio.First = -1) then
					FRadio.First := Result.FPosition;

				if (FRadio.Last < Result.FPosition) then
					FRadio.Last := Result.FPosition;

				Delete(Result.FCaption, 1, 1);

				if (Length(Result.Caption) > 0) and (Result.Caption[1] = TM_RADIO) then
				begin
					FRadio.Checked := Result.FPosition;
					Delete(Result.FCaption, 1, 1);
				end;
			end;

		end;
	end;

	AppendMenu(FHandle, Flag, Result.FUniqueID, PChar(Result.FCaption));

	if (Result.FParent.FUniqueID > -1) then
		ModifyMenu(FParent.FHandle, FUniqueID, MF_POPUP, FHandle, PChar(Result.FParent.FCaption));

	if (FRadio.First > -1) and (FRadio.Last > -1) and (FRadio.Checked <> NativeUInt(-1)) then
		CheckMenuRadioItem(FHandle, FRadio.First, FRadio.Last, FRadio.Checked, MF_BYPOSITION);

	Result.OnItemAdd(Result);
end;

end.
