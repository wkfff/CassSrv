object UIBTransactionEditForm: TUIBTransactionEditForm
  Left = 617
  Top = 383
  Width = 339
  Height = 273
  HorzScrollBar.Range = 329
  VertScrollBar.Range = 241
  ActiveControl = CommonBox
  AutoScroll = False
  Caption = 'UIB Transaction Editor'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = 11
  Font.Name = 'MS Sans Serif'
  Font.Pitch = fpVariable
  Font.Style = []
  OldCreateOrder = True
  Position = poDesktopCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 0
    Top = 0
    Width = 46
    Height = 13
    Caption = 'Commons'
  end
  object CommonBox: TComboBox
    Left = 56
    Top = 0
    Width = 257
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 0
    OnChange = CommonBoxChange
    Items.Strings = (
      'Default'
      'SnapShot'
      'Read Committed'
      'Read Only Table Stability'
      'Read Write Table Stability'
      '<custom>')
  end
  object OK: TButton
    Left = 8
    Top = 216
    Width = 75
    Height = 25
    Caption = '&OK'
    ModalResult = 1
    TabOrder = 2
    OnClick = OKClick
  end
  object Cancel: TButton
    Left = 248
    Top = 216
    Width = 75
    Height = 25
    Caption = '&Cancel'
    ModalResult = 2
    TabOrder = 3
  end
  object OptionPanel: TPanel
    Left = 0
    Top = 24
    Width = 329
    Height = 185
    TabOrder = 1
    object ChkConsistency: TCheckBox
      Left = 8
      Top = 8
      Width = 97
      Height = 17
      Caption = 'Consistency'
      TabOrder = 0
      OnClick = ChkOptionClick
    end
    object ChkConcurrency: TCheckBox
      Tag = 1
      Left = 8
      Top = 24
      Width = 97
      Height = 17
      Caption = 'Concurrency'
      TabOrder = 1
      OnClick = ChkOptionClick
    end
    object ChkShared: TCheckBox
      Tag = 2
      Left = 216
      Top = 8
      Width = 97
      Height = 17
      Caption = 'Shared'
      TabOrder = 12
      OnClick = ChkOptionClick
    end
    object ChkProtected: TCheckBox
      Tag = 3
      Left = 216
      Top = 24
      Width = 97
      Height = 17
      Caption = 'Protected'
      TabOrder = 13
      OnClick = ChkOptionClick
    end
    object ChkExclusive: TCheckBox
      Tag = 4
      Left = 216
      Top = 40
      Width = 97
      Height = 17
      Caption = 'Exclusive'
      TabOrder = 14
      OnClick = ChkOptionClick
    end
    object ChkWait: TCheckBox
      Tag = 5
      Left = 8
      Top = 40
      Width = 97
      Height = 17
      Caption = 'Wait'
      TabOrder = 2
      OnClick = ChkOptionClick
    end
    object ChkNowait: TCheckBox
      Tag = 6
      Left = 8
      Top = 56
      Width = 97
      Height = 17
      Caption = 'Nowait'
      TabOrder = 3
      OnClick = ChkOptionClick
    end
    object ChkRead: TCheckBox
      Tag = 7
      Left = 8
      Top = 72
      Width = 97
      Height = 17
      Caption = 'Read'
      TabOrder = 4
      OnClick = ChkOptionClick
    end
    object ChkWrite: TCheckBox
      Tag = 8
      Left = 8
      Top = 88
      Width = 97
      Height = 17
      Caption = 'Write'
      TabOrder = 5
      OnClick = ChkOptionClick
    end
    object ChkLockRead: TCheckBox
      Tag = 9
      Left = 8
      Top = 112
      Width = 97
      Height = 17
      Caption = 'LockRead'
      TabOrder = 18
      OnClick = ChkOptionClick
    end
    object ChkLockWrite: TCheckBox
      Tag = 10
      Left = 8
      Top = 136
      Width = 97
      Height = 17
      Caption = 'LockWrite'
      TabOrder = 20
      OnClick = ChkOptionClick
    end
    object ChkVerbTime: TCheckBox
      Tag = 11
      Left = 216
      Top = 56
      Width = 97
      Height = 17
      Caption = 'VerbTime'
      TabOrder = 15
      OnClick = ChkOptionClick
    end
    object ChkCommitTime: TCheckBox
      Tag = 12
      Left = 216
      Top = 72
      Width = 97
      Height = 17
      Caption = 'CommitTime'
      TabOrder = 16
      OnClick = ChkOptionClick
    end
    object ChkIgnoreLimbo: TCheckBox
      Tag = 13
      Left = 216
      Top = 88
      Width = 97
      Height = 17
      Caption = 'IgnoreLimbo'
      TabOrder = 17
      OnClick = ChkOptionClick
    end
    object ChkReadCommitted: TCheckBox
      Tag = 14
      Left = 112
      Top = 8
      Width = 97
      Height = 17
      Caption = 'ReadCommitted'
      TabOrder = 6
      OnClick = ChkOptionClick
    end
    object ChkAutoCommit: TCheckBox
      Tag = 15
      Left = 112
      Top = 56
      Width = 97
      Height = 17
      Caption = 'AutoCommit'
      TabOrder = 9
      OnClick = ChkOptionClick
    end
    object ChkRecVersion: TCheckBox
      Tag = 16
      Left = 112
      Top = 24
      Width = 97
      Height = 17
      Caption = 'RecVersion'
      TabOrder = 7
      OnClick = ChkOptionClick
    end
    object ChkNoRecVersion: TCheckBox
      Tag = 17
      Left = 112
      Top = 40
      Width = 97
      Height = 17
      Caption = 'NoRecVersion'
      TabOrder = 8
      OnClick = ChkOptionClick
    end
    object ChkRestartRequests: TCheckBox
      Tag = 18
      Left = 112
      Top = 72
      Width = 97
      Height = 17
      Caption = 'RestartRequests'
      TabOrder = 10
      OnClick = ChkOptionClick
    end
    object ChkNoAutoUndo: TCheckBox
      Tag = 19
      Left = 112
      Top = 88
      Width = 97
      Height = 17
      Caption = 'NoAutoUndo'
      TabOrder = 11
      OnClick = ChkOptionClick
    end
    object LockReadTables: TEdit
      Left = 104
      Top = 112
      Width = 217
      Height = 21
      TabOrder = 19
    end
    object LockWriteTable: TEdit
      Left = 104
      Top = 136
      Width = 217
      Height = 21
      TabOrder = 21
    end
    object ChkLockTimeOut: TCheckBox
      Tag = 20
      Left = 8
      Top = 157
      Width = 97
      Height = 23
      Caption = 'LockTimeout'
      TabOrder = 22
      Visible = False
      OnClick = ChkOptionClick
    end
    object LockTimeoutValue: TEdit
      Left = 104
      Top = 160
      Width = 57
      Height = 21
      TabOrder = 23
      Text = '0'
      Visible = False
    end
  end
end
