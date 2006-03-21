{ $Id$ }
{
 /***************************************************************************
                               PFDCtrls.pas
                               ------------
                  Abstract: Implements the building blocks elements
                            for the PFD diagram.
                  Initial Revision : 09/03/2006
                  Author: Samuel Jorge Marques Cartaxo

 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  This file is part of the OpSim - OPEN SOURCE PROCESS SIMULATOR           *
 *                                                                           *
 *  See the file COPYING.GPL, included in this distribution,                 *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
unit PFDCtrls;

interface

uses
  SysUtils, Windows, Forms, Classes, Dialogs, Graphics, Controls, ExtCtrls, StdCtrls,
  Types, Math, PFDGraph, LCLProc;

type

  TPFDWorkplace = class;

  TPFDFrame = class (TGraphicControl)
  protected
    procedure Paint; override;
  end;
  
  TPFDControl = class (TGraphicControl)
  private
    DefaultHeight: Integer;
    DefaultWidth: Integer;
    FDragFrame: TPFDFrame;
    FDrawWireFrame: Boolean;
    FScale: Double;
    FSelected: Boolean;
    StartPoint: TPoint;
    function GetOffsetX: Integer;
    function GetOffsetY: Integer;
    function GetPFDWorkplace: TPFDWorkplace;
    procedure SetScale(Value: Double);
    procedure SetSelected(Value: Boolean);
  protected
    procedure ChangeScale(M, D: Integer); override;
    procedure DoClick(Sender: TObject);
    procedure DoMouseDown(Sender: TObject; Button: TMouseButton ; Shift: 
            TShiftState; X, Y: Integer); virtual;
    procedure DoMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer); 
            virtual;
    procedure DoMouseUp(Sender: TObject; Button: TMouseButton ; Shift: 
            TShiftState; X, Y: Integer); virtual;
    procedure Paint; override;
  public
    constructor Create(AOwner: TPFDWorkplace); reintroduce; virtual;
    property Canvas;
    property DrawWireFrame: Boolean read FDrawWireFrame write FDrawWireFrame;
    property OffsetX: Integer read GetOffsetX;
    property OffsetY: Integer read GetOffsetY;
    property PFDWorkplace: TPFDWorkplace read GetPFDWorkplace;
    property Scale: Double read FScale write SetScale;
    property Selected: Boolean read FSelected write SetSelected;
  published
    property Align;
    property Anchors;
    property Color;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;
  end;
  
  TPFDMixer = class (TPFDControl)
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TPFDWorkplace); override;
  end;
  
  TPFDValve = class (TPFDControl)
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TPFDWorkplace); override;
  end;
  
  TPFDWorkplace = class (TScrollBox)
  private
    Active: Boolean;
    CurrentGuideLinesCenter: TPoint;
    procedure DrawGuideLines;
    procedure EraseGuideLines;
  protected
    procedure DoEnter(Sender: TObject);
    procedure DoExit(Sender: TObject);
    procedure DoMouseDown(Sender: TObject; Button: TMouseButton ; Shift: 
            TShiftState; X, Y: Integer);
    procedure DoMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure DoMouseUp(Sender: TObject; Button: TMouseButton ; Shift: 
            TShiftState; X, Y: Integer);
    procedure DoResize(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure NotifyRepaint(APFDControl: TPFDControl);
    procedure ResetGuideLines;
  end;
  
implementation

uses
  Utils;

type
  TGradientStyles = (gsCenter, gsHorizontal, gsVertical, gsTopToBottom, gsBottomToTop, gsLeftToRight, gsRightToLeft);
  TGradientStyle = set of TGradientStyles;

function HeightOf(ARect: TRect): Integer;
begin
  Result := ARect.Bottom - ARect.Top;
end;

function WidthOf(ARect: TRect): Integer;
begin
  Result := ARect.Right - ARect.Left;
end;

procedure GradientFillRect(Canvas: TCanvas; ARect: TRect; Origin: TPoint; StartColor,
  EndColor: TColor; Style: TGradientStyles; Colors: Byte);
var
  StartRGB: array [0..2] of Byte; { Start RGB values }
  RGBDelta: array [0..2] of Integer; { Difference between start and end RGB values }
  ColorBand: TRect; { Color band rectangular coordinates }
  I, Delta: Integer;
begin
  StartColor := ColorToRGB(StartColor);
  EndColor := ColorToRGB(EndColor);
  case Style of
    gsTopToBottom, gsLeftToRight, gsCenter:
      begin
        { Set the Red, Green and Blue colors }
        StartRGB[0] := GetRValue(StartColor);
        StartRGB[1] := GetGValue(StartColor);
        StartRGB[2] := GetBValue(StartColor);
        { Calculate the difference between begin and end RGB values }
        RGBDelta[0] := GetRValue(EndColor) - StartRGB[0];
        RGBDelta[1] := GetGValue(EndColor) - StartRGB[1];
        RGBDelta[2] := GetBValue(EndColor) - StartRGB[2];
      end;
    gsBottomToTop, gsRightToLeft:
      begin
        { Set the Red, Green and Blue colors }
        { Reverse of TopToBottom and LeftToRight directions }
        StartRGB[0] := GetRValue(EndColor);
        StartRGB[1] := GetGValue(EndColor);
        StartRGB[2] := GetBValue(EndColor);
        { Calculate the difference between begin and end RGB values }
        { Reverse of TopToBottom and LeftToRight directions }
        RGBDelta[0] := GetRValue(StartColor) - StartRGB[0];
        RGBDelta[1] := GetGValue(StartColor) - StartRGB[1];
        RGBDelta[2] := GetBValue(StartColor) - StartRGB[2];
      end;
  end;//case

  { Calculate the color band's coordinates }
  ColorBand := ARect;
  if Style in [gsTopToBottom, gsBottomToTop, gsCenter] then
  begin
    Colors := Max(2, Min(Colors, HeightOf(ARect)));
    Delta := HeightOf(ARect) div Colors;
  end
  else
  begin
    Colors := Max(2, Min(Colors, WidthOf(ARect)));
    Delta := WidthOf(ARect) div Colors;
  end;

  with Canvas.Pen do
  begin { Set the pen style and mode }
    Style := psSolid;
    Mode := pmCopy;
  end;

  with Canvas do begin

  end;//with
end;

procedure GradientFillPolygon(Canvas: TCanvas; Points: array of TPoint; StartColor,
  EndColor: TColor; Colors: Byte);
var
  StartRGB: array [0..2] of Byte; { Start RGB values }
  RGBDelta: array [0..2] of Integer; { Difference between start and end RGB values }
  ColorBand, BoundRect: TRect; { Color band rectangular coordinates }
  I, Delta: Integer;
begin
  //Calculate a bound rectangle.
  BoundRect := Rect(MaxInt,MaxInt,-MaxInt,-MaxInt);
  for I := Low(Points) to High(Points) do begin
    if Points[I].X < BoundRect.Left then
      BoundRect.Left := Points[I].X;
    if Points[I].Y < BoundRect.Top then
      BoundRect.Top := Points[I].Y;
    if Points[I].X > BoundRect.Right then
      BoundRect.Right := Points[I].X;
    if Points[I].Y > BoundRect.Bottom then
      BoundRect.Bottom := Points[I].Y;
  end;//for
end;

procedure GradientFillGuadrilateral(Canvas: TCanvas; Points: array of TPoint; StartColor,
  EndColor: TColor; Colors: Byte);
var
  StartRGB: array [0..2] of Byte; { Start RGB values }
  RGBDelta: array [0..2] of Integer; { Difference between start and end RGB values }
  ColorBand, BoundRect: TRect; { Color band rectangular coordinates }
  I, Delta, DV1, DV2: Integer;
  V1, V2: TPoint; //Vectors for advancing the band.
begin
  //Takes four points. The first two in clockwise direction
  //are the start side, the last two are the end side.
  V1.X := Points[0].X-Points[3].X;
  V1.Y := Points[0].Y-Points[3].Y;
  DV1 := Round(Norm([V1.X,V1.Y])/Colors);
  V2.X := Points[0].X-Points[3].X;
  V2.Y := Points[0].Y-Points[3].Y;
  DV2 := Round(Norm([V2.X,V2.Y])/Colors);

  //Unit vectors
  {V1.X := V1.X/DV1;
  V1.Y := V1.Y/DV1;
  V2.X := V2.X/DV2;
  V2.Y := V2.Y/DV2;}
end;

procedure PaintGuideLines(ACanvas: TCanvas; ARect: TRect;
        ACenter: TPoint); overload;
begin
  //Paint the guidelines.
  with ACanvas, ARect do begin
    Pen.Color := clRed;
    Pen.Mode := pmNot;
    Pen.Style := psSolid;
    //Draw the horizontal guideline.
    PenPos := Point(0, ACenter.Y);
    LineTo(Right-Left, ACenter.Y);
    //Draw the vertical guideline.
    PenPos := Point(ACenter.X, 0);
    LineTo(ACenter.X, Bottom-Top);
  end;//with
end;

procedure PaintGuideLines(ACanvas: TCanvas; ARect, AExcludeRect: TRect;
        ACenter: TPoint); overload;
begin
  //Paint the guidelines.
  with ACanvas, ARect do begin
    Pen.Color := clRed;
    Pen.Mode := pmNot;
    Pen.Style := psSolid;
    //Draw the horizontal guideline.
    PenPos := Point(0, ACenter.Y);
    LineTo(AExcludeRect.Left, ACenter.Y);
    PenPos := Point(AExcludeRect.Right, ACenter.Y);
    LineTo(Right-Left, ACenter.Y);
    //Draw the vertical guideline.
    PenPos := Point(ACenter.X, 0);
    LineTo(ACenter.X, Bottom-Top);
  end;//with
end;

{
********************************** TPFDFrame ***********************************
}
procedure TPFDFrame.Paint;
var
  P1, P2: TPoint;
begin
  with Canvas do begin
    Pen.Color := clRed;
    Pen.Mode := pmXor;
    Pen.Style := psSolid;
    Brush.Style := bsClear;
    Rectangle(Rect(0,0,Self.Width-1,Self.Height-1));
  end;//with
  PaintGuideLines(Canvas, ClientRect, ScreenToClient(Mouse.CursorPos));
end;

{
********************************* TPFDControl **********************************
}
constructor TPFDControl.Create(AOwner: TPFDWorkplace);
begin
  inherited Create(AOwner);
  
  Parent := TPFDWorkplace(Owner);
  
  //Each descendent should define its default dimensions, for when scale factor
  //is one.
  DefaultWidth := 105;
  DefaultHeight := 105;
  
  //Initializes size.
  Scale := 1;
  
  OnMouseDown := DoMouseDown;
  OnMouseMove := DoMouseMove;
  OnMouseUp := DoMouseUp;
  OnMouseMove := DoMouseMove;
  OnClick := DoClick;
end;

procedure TPFDControl.ChangeScale(M, D: Integer);
begin
  inherited ChangeScale(M, D);
  //Reserved to scale other associated controls, e.g. label tags.
end;

procedure TPFDControl.DoClick(Sender: TObject);
begin
  
end;

procedure TPFDControl.DoMouseDown(Sender: TObject; Button: TMouseButton ; 
        Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  Selected := True;
  StartPoint := Point(X,Y);
  
  //Needs to notify the mouse event over the control in order the PFDWorkplace
  //update drawings on its canvas.
  P := PFDWorkplace.ScreenToClient(ClientToScreen(Point(X,Y)));
  PFDWorkplace.DoMouseDown(Sender, Button, Shift, P.X, P.Y);
end;

procedure TPFDControl.DoMouseMove(Sender: TObject; Shift: TShiftState; X, Y: 
        Integer);
var
  P: TPoint;
begin
  if MouseCapture then begin
    //Create drag border.
    if not Assigned(FDragFrame) then begin
      FDragFrame := TPFDFrame.Create(Self);
      FDragFrame.Parent := Parent;
      FDragFrame.SetBounds(Left, Top, Width, Height);
    end;//if
    //Move the border frame.
    with FDragFrame do begin
      Left := Left + X - StartPoint.X;
      Top := Top + Y - StartPoint.Y;
      StartPoint := Point(X,Y);
    end;//with
  end;//if
  
  //Needs to notify mouse movements over the control in order the PFDWorkplace
  //update drawings on its canvas.
  P := PFDWorkplace.ScreenToClient(ClientToScreen(Point(X,Y)));
  PFDWorkplace.DoMouseMove(Sender, Shift, P.X, P.Y);
end;

procedure TPFDControl.DoMouseUp(Sender: TObject; Button: TMouseButton ; Shift: 
        TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  if Assigned(FDragFrame) then begin
    Left := FDragFrame.Left;
    Top := FDragFrame.Top;
    FreeAndNil(FDragFrame);
  end;//if
  
  //Needs to notify the mouse event over the control in order the PFDWorkplace
  //update drawings on its canvas.
  P := PFDWorkplace.ScreenToClient(ClientToScreen(Point(X,Y)));
  PFDWorkplace.DoMouseUp(Sender, Button, Shift, P.X, P.Y);
end;

function TPFDControl.GetOffsetX: Integer;
begin
  Result := Width div 7;
end;

function TPFDControl.GetOffsetY: Integer;
begin
  Result := Height div 7;
end;

function TPFDControl.GetPFDWorkplace: TPFDWorkplace;
begin
  Result := TPFDWorkplace(Owner);
end;

procedure TPFDControl.Paint;
begin
  if Selected then begin
    with Canvas do begin
      Pen.Style := psSolid;
      Pen.Mode := pmCopy;
      Pen.Color := clWhite;
      Pen.Width := 1;
      Brush.Style := bsClear;
      //Lazarus needs a correction of one pixel.
      Rectangle(Rect(0,0,Self.Width-1,Self.Height-1));
      //Debugln(Format('TPFDControl Width: %s', [IntToStr(Self.Width)]));
      //Debugln(Format('TPFDControl Height: %s', [IntToStr(Self.Height)]));
    end;//with
  end;//if
  
  //Notify workplace to allow canvas update.
  PFDWorkplace.NotifyRepaint(Self);
  
  //Defines a standard canvas to be used by the descendents. The canvas will be
  //automatica defined when descendents controls invoke the inherited Paint
  //method.
  with Canvas do begin
    Pen.color := clBlack;
    Pen.Width := 1;
    Brush.Style := bsSolid;
    Brush.Color := clWhite;
  end;//with
end;

procedure TPFDControl.SetScale(Value: Double);
begin
  FScale := Value;
  Width := Round(Scale * DefaultWidth);
  Height := Round(Scale * DefaultHeight);
end;

procedure TPFDControl.SetSelected(Value: Boolean);
begin
  FSelected := Value;
  Invalidate;
end;

{
********************************** TPFDMixer ***********************************
}
constructor TPFDMixer.Create(AOwner: TPFDWorkplace);
begin
  inherited Create(AOwner);
  DefaultWidth := 30;
  DefaultHeight := 44;
  Scale := 1;
end;

procedure TPFDMixer.Paint;
var
  R: TRect;
begin
  inherited Paint;
  R := Rect(ClientRect.Left+OffsetX, OffsetY, ClientRect.Right-OffsetX, ClientRect.Bottom-OffsetY);
  PaintMixer(Canvas, R, 0);
end;

{
********************************** TPFDValve ***********************************
}
constructor TPFDValve.Create(AOwner: TPFDWorkplace);
begin
  inherited Create(AOwner);
  DefaultWidth := 30;
  DefaultHeight := 20;
  Scale := 1;
end;

procedure TPFDValve.Paint;
var
  R: TRect;
begin
  inherited Paint;
  R := Rect(ClientRect.Left+OffsetX, OffsetY, ClientRect.Right-OffsetX, ClientRect.Bottom-OffsetY);
  PaintValve(Canvas, R, 0);
end;

{
******************************** TPFDWorkplace *********************************
}
constructor TPFDWorkplace.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Color := $00808040;
  Align := alClient;
  OnMouseDown := DoMouseDown;
  OnMouseUp := DoMouseUp;
  OnMouseMove := DoMouseMove;
  OnEnter := DoEnter;
  OnExit := DoExit;
  OnResize := DoResize;
end;

procedure TPFDWorkplace.DoEnter(Sender: TObject);
begin
  //Set flag to indicate that PFDWorkplace has input focus.
  Active := True;
end;

procedure TPFDWorkplace.DoExit(Sender: TObject);
begin
  //We need erase the last drawn line when losing the input focus. Otherwise
  //the canvas will be stained.
  EraseGuideLines;
  Active := False;
end;

procedure TPFDWorkplace.DoMouseDown(Sender: TObject; Button: TMouseButton ; 
        Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
begin
  //It is needed to erase the lines to avoid interference with repainting of
  //the controls under the lines.
  EraseGuideLines;
  //Deselect other controls if Shift key is not pressed.
  if (Shift <> [ssShift, ssLeft]) then
    for I := 0 to ControlCount - 1 do
      if  (Controls[I] <> Sender) and
          (Controls[I] is TPFDControl) then
        TPFDControl(Controls[I]).Selected := False;
end;

procedure TPFDWorkplace.DoMouseMove(Sender: TObject; Shift: TShiftState; X, Y: 
        Integer);
begin
  if Active then begin
    ResetGuideLines;
  end;//if
end;

procedure TPFDWorkplace.DoMouseUp(Sender: TObject; Button: TMouseButton ; 
        Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
begin
  DrawGuideLines;
end;

procedure TPFDWorkplace.DoResize(Sender: TObject);
begin
  SetInvalidPoint(CurrentGuideLinesCenter);
end;

procedure TPFDWorkplace.DrawGuideLines;
var
  P: TPoint;
begin
  //Draw the new line only if the last one was erased and if mouse pointer
  //is over the control.
  P := ScreenToClient(Mouse.CursorPos);
  if IsInvalidPoint(CurrentGuideLinesCenter) and
     PtInRect(ClientRect, P) then begin
    PaintGuideLines(Canvas, ClientRect, P);
    CurrentGuideLinesCenter := P;
  end;//if
end;

procedure TPFDWorkplace.EraseGuideLines;
begin
  if not IsInvalidPoint(CurrentGuideLinesCenter) then begin
    PaintGuideLines(Canvas, ClientRect, CurrentGuideLinesCenter);
    //Sets an invalid coordinate to indicate that there is no drawn line now.
    SetInvalidPoint(CurrentGuideLinesCenter);
  end;//if
end;

procedure TPFDWorkplace.NotifyRepaint(APFDControl: TPFDControl);
begin
  //Reserved for processing after controls repainting.
end;

procedure TPFDWorkplace.ResetGuideLines;
begin
  EraseGuideLines;
  DrawGuideLines;
end;

end.
