{ $Id$ }
{
 /***************************************************************************

                  Abstract: Implements the building blocks elements
                            for the PFD diagram.
                  Initial Revision : 09/03/2006
                  Authors:
                    - Samuel Jorge Marques Cartaxo
                    - Additional contributors...

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
  SysUtils, Forms, Classes, Dialogs, Graphics, Controls, ExtCtrls, StdCtrls,
  Types, Math, PFDGraph, LCLProc, LMessages, GraphMath, LCLMessageGlue;

type

  TPFDControlClass = class of TPFDControl;

  TPFDWorkplace = class;

  TPFDControl = class (TGraphicControl)
  private
    DefaultHeight: Integer;
    DefaultWidth: Integer;
    FDrawWireFrame: Boolean;
    FScale: Double;
    FSelected: Boolean;
    StartDragPoint: TPoint;
    function GetOffsetX: Integer;
    function GetOffsetY: Integer;
    function GetPFDWorkplace: TPFDWorkplace;
    procedure SetScale(Value: Double);
    procedure SetSelected(Value: Boolean);
  protected
    procedure ChangeScale(M, D: Integer); override;
    procedure Click; override;
    procedure MouseDown(Button: TMouseButton ; Shift: TShiftState; X, Y: 
            Integer); override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton ; Shift: TShiftState; X, Y: Integer);
            override;
    procedure Paint; override;
    procedure WMLButtonDown(Var Message: TLMLButtonDown); message 
            LM_LBUTTONDOWN;
    procedure WMLButtonUp(var Message: TLMLButtonUp); message LM_LBUTTONUP;
    procedure WMRButtonDown(Var Message: TLMRButtonDown); message 
            LM_RBUTTONDOWN;
    procedure WMRButtonUp(var Message: TLMRButtonUp); message LM_RBUTTONUP;
  public
    constructor Create(AOwner: TPFDWorkplace); reintroduce; virtual;
    property Canvas;
    property DrawWireFrame: Boolean read FDrawWireFrame write FDrawWireFrame;
    property OffsetX: Integer read GetOffsetX;
    property OffsetY: Integer read GetOffsetY;
    property PFDWorkplace: TPFDWorkplace read GetPFDWorkplace;
    property Scale: Double read FScale write SetScale;
    property Selected: Boolean read FSelected write SetSelected;
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
  
  TPFDWorkplace = class (TPanel)
  private
    Active: Boolean;
    CurrentGuideLinesCenter: TPoint;
    FDragControl: TControl;
    Resized: Boolean;
    procedure DrawGuideLines;
    procedure EraseGuideLines;
  protected
    procedure CMMouseEnter(var Message :TLMessage); message CM_MouseEnter;
    procedure CMMouseLeave(var Message :TLMessage); message CM_MouseLeave;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure MouseDown(Button: TMouseButton ; Shift: TShiftState; X, Y: 
            Integer); override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton ; Shift: TShiftState; X, Y: Integer);
            override;
    procedure Paint; override;
    procedure PaintDragFrames(Origin, Dest: TPoint); overload;
    procedure Resize; override;
    procedure WMKillFocus(var Message: TLMKillFocus); message LM_KILLFOCUS;
    procedure WMSetFocus(var Message: TLMSetFocus); message LM_SETFOCUS;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ResetGuideLines;
    property DragControl: TControl read FDragControl write FDragControl;
  end;
  
implementation

uses
  Utils, UnitopPalletU;

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

(*procedure GradientFillRect(Canvas: TCanvas; ARect: TRect; Origin: TPoint; StartColor,
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
end;*)

procedure PaintGuideLines(ACanvas: TCanvas; ARect: TRect;
        ACenter: TPoint); overload;
begin
  //Paint the guidelines.
  with ACanvas, ARect do begin
    Pen.Width := 1;
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
    Pen.Width := 1;
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
  
  DrawWireFrame := False;
end;

procedure TPFDControl.ChangeScale(M, D: Integer);
begin
  inherited ChangeScale(M, D);
  //Reserved to scale other associated controls, e.g. label tags.
end;

procedure TPFDControl.Click;
begin
  inherited Click;
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

procedure TPFDControl.MouseDown(Button: TMouseButton ; Shift: TShiftState; X, 
        Y: Integer);
var
  P: TPoint;
  I: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  //If Shift is pressed while clicking, then negate the selection state of the
  //control. Otherwise, always select it.
  if (Shift = [ssShift, ssLeft]) then begin
    Selected := not Selected;
  end
  else begin
    //Clicking a deselected control, without the Shift key pressed, causes the
    //selection of the clicked control and deselects all the others. If the clicked
    //control is already selected, then the selection state remains the same.
    if not Selected then
      with PFDWorkplace do
        for I := 0 to ControlCount - 1 do
          if  (Controls[I] <> Self) and
              (Controls[I] is TPFDControl) then
            TPFDControl(Controls[I]).Selected := False;
    //The control becomes the only selected one.
    Selected := True;
  end;//if
  
  StartDragPoint := Point(X,Y);
  
  //Needs to notify the mouse event over the control in order the PFDWorkplace
  //update drawings on its canvas.
  P := Parent.ScreenToClient(ClientToScreen(Point(X,Y)));
  (Parent as TPFDWorkplace).MouseDown(Button, Shift, P.X, P.Y);
  //LCLSendMouseDownMsg(Parent, P.X, P.Y, Button, Shift);
end;

procedure TPFDControl.MouseEnter;
begin
  inherited MouseEnter;
  //Necessary to notify PFDWorkplace because if user alternate applications
  //using Alt+Tab and the application get focus with the mouse pointer over
  //a PFD control, then MouseEnter will not triggers on PFDWorkplace.
  PFDWorkplace.MouseEnter;
end;

procedure TPFDControl.MouseLeave;
begin
  inherited MouseLeave;
  //Necessary to notify PFDWorkplace because if user alternate applications
  //using Alt+Tab and the application lose focus with the mouse pointer over
  //a PFD control, then MouseLeave will not triggers on PFDWorkplace.
  PFDWorkplace.MouseLeave;
end;

procedure TPFDControl.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  inherited MouseMove(Shift, X, Y);
  
  //Debugln(ClassName,': MouseMove');
  
  //Needs to notify mouse movements over the control in order the PFDWorkplace
  //update drawings on its canvas.
  P := Parent.ScreenToClient(ClientToScreen(Point(X,Y)));
  (Parent as TPFDWorkplace).MouseMove(Shift, P.X, P.Y);
  //LCLSendMouseMoveMsg(Parent, P.X, P.Y, Shift);
end;

procedure TPFDControl.MouseUp(Button: TMouseButton ; Shift: TShiftState; X, Y: 
        Integer);
var
  P: TPoint;
begin
  inherited MouseUp(Button, Shift, X, Y);
  //Needs to notify the mouse event over the control in order the PFDWorkplace
  //update drawings on its canvas.
  P := Parent.ScreenToClient(ClientToScreen(Point(X,Y)));
  (Parent as TPFDWorkplace).MouseUp(Button, Shift, P.X, P.Y);
  //LCLSendMouseUpMsg(Parent, P.X, P.Y, Button, Shift);
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
  
  //Defines a standard canvas to be used by the descendents. The canvas will be
  //automatica defined when descendents controls invoke the inherited Paint
  //method.
  with Canvas do begin
    Pen.Width := 1;
    Brush.Color := clWhite;
    if DrawWireFrame then begin
      Pen.color := clWhite;
      Brush.Style := bsClear;
    end
    else begin
      Pen.color := clBlack;
      Brush.Style := bsSolid;
    end;//if
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

procedure TPFDControl.WMLButtonDown(Var Message: TLMLButtonDown);
  
  //var
    //Shift: TShiftState;
    //I: Integer;
  
begin
  inherited WMLButtonDown(Message);
  
  //with Message do begin
    //StartDragPoint := Point(XPos,YPos);
    //Shift := KeysToShiftState(Keys);
  //end;//with
  
  ////If Shift is pressed while clicking, then negate the selection state of the
  ////control. Otherwise, always select it.
  //if (ssShift in Shift) then begin
    //Selected := not Selected;
  //end
  //else begin
    ////Clicking a deselected control, without the Shift key pressed, causes the
    ////selection of the clicked control and deselects all the others. If the clicked
    ////control is already selected, then the selection state remains the same.
    //if not Selected then
      //with PFDWorkplace do
        //for I := 0 to ControlCount - 1 do
          //if  (Controls[I] <> Self) and
              //(Controls[I] is TPFDControl) then
            //TPFDControl(Controls[I]).Selected := False;
    ////The control becomes the only selected one.
    //Selected := True;
  //end;//if
  
  ////Pass mouse processing to the parent.
  //Parent.MouseCapture := True;
end;

procedure TPFDControl.WMLButtonUp(var Message: TLMLButtonUp);
begin
  inherited WMLButtonUp(Message);
end;

procedure TPFDControl.WMRButtonDown(Var Message: TLMRButtonDown);
begin
  inherited WMRButtonDown(Message);
end;

procedure TPFDControl.WMRButtonUp(var Message: TLMRButtonUp);
begin
  inherited WMRButtonUp(Message);
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
  //Color := $00808040;
  //Color := clGreen;
  //Align := alClient;
  SetBounds(0, 0, Screen.Width, Screen.Height);
  SetInvalidPoint(CurrentGuideLinesCenter);
  Resized := False;
end;

procedure TPFDWorkplace.CMMouseEnter(var Message :TLMessage);
begin
  //It is necessary to overide this custom message handler, in order the
  //PFD workplace be notified about the mouse enter event when the
  //user switch to the simulator using alt+tab and the mouse pointer
  //falls over a PFD control. Overriding the MouseEnter method is not
  //sufficient (Lazarus bug?).
  inherited CMMouseEnter(Message);
  //MouseEnter;
end;

procedure TPFDWorkplace.CMMouseLeave(var Message :TLMessage);
begin
  //It is necessary to overide this custom message handler, in order the
  //PFD workplace be notified about the mouse leave event when the
  //user switch from the simulator using alt+tab and the mouse pointer
  //is over a PFD control. Overriding the MouseLeave method is not
  //sufficient (Lazarus bug?).
  inherited CMMouseLeave(Message);
  //MouseLeave;
end;

procedure TPFDWorkplace.DoEnter;
begin
  inherited DoEnter;
  //For some reason, this overriden method does not trigger on Linux,
  //therefore we have to abandon the Active flag.
  
  //Set flag to indicate that PFDWorkplace has input focus.
  Active := True;
end;

procedure TPFDWorkplace.DoExit;
begin
  inherited DoExit;
  //For some reason, this overriden method does not trigger on Linux,
  //therefore we have to abandon the Active flag.
  
  Active := False;
end;

procedure TPFDWorkplace.DrawGuideLines;
var
  P, Origin: TPoint;
begin
  //Draw the new line only if the last one was erased and if mouse pointer
  //is over the control.
  P := ScreenToClient(Mouse.CursorPos);
  if IsInvalidPoint(CurrentGuideLinesCenter) and
     PtInRect(ClientRect, P) then begin
  
    //Draw the lines.
    PaintGuideLines(Canvas, ClientRect, P);
    //Debugln('DrawGuideLines:',' X=',IntToStr(P.X), ' Y=', IntToStr(P.X));
  
    //Draw frames for each selected control while dragging.
    if DragControl <> nil then begin
      with TPFDControl(DragControl) do begin
        Origin := Self.ScreenToClient(ClientToScreen(StartDragPoint));
        PaintDragFrames(Origin, P);
      end;//with
    end;//if
  
    CurrentGuideLinesCenter := P;
  
    //Needed to allow application to process message queue. For some
    //reason, calling Invalidate or Repaint does not paint the canvas
    //correctly.
    Application.ProcessMessages;
  
  end;//if
end;

procedure TPFDWorkplace.EraseGuideLines;
var
  Origin: TPoint;
begin
  if not IsInvalidPoint(CurrentGuideLinesCenter) then begin
  
    //Erase guidelines.
    PaintGuideLines(Canvas, ClientRect, CurrentGuideLinesCenter);
    //Debugln('EraseGuideLines:',' X=',IntToStr(CurrentGuideLinesCenter.X), ' Y=', IntToStr(CurrentGuideLinesCenter.X));
  
    //Erase frames for each selected control while dragging.
    if DragControl <> nil then begin
      with TPFDControl(DragControl) do begin
        Origin := Self.ScreenToClient(ClientToScreen(StartDragPoint));
        PaintDragFrames(Origin, CurrentGuideLinesCenter);
      end;//with
    end;//if
  
    //Sets an invalid coordinate to indicate that there is no drawn line now.
    SetInvalidPoint(CurrentGuideLinesCenter);
  
    //Needed to allow application to process message queue. For some
    //reason, calling Invalidate or Repaint does not paint the canvas
    //correctly.
    Application.ProcessMessages;
  
  end;//if
end;

procedure TPFDWorkplace.MouseDown(Button: TMouseButton ; Shift: TShiftState; X, 
        Y: Integer);
var
  I: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  
  //Reference the dragged control for later manipulation.
  //It seems that GetCaptureControl does not work properly on Linux,
  //therefore we have to find the clicked control manualy.
  DragControl := nil;
  if (ControlAtPos(Point(X,Y), False) is TPFDControl) then
    DragControl := ControlAtPos(Point(X,Y), False);
  
  //It is needed to erase the lines to avoid interference with repainting of
  //the controls under the lines.
  EraseGuideLines;
  
  //Deselects all controls if a empty workplace are is clicked.
  if not (DragControl is TPFDControl) then
    for I := 0 to ControlCount - 1 do
      if  (Controls[I] is TPFDControl) then
        TPFDControl(Controls[I]).Selected := False;
  
  //If dropping a new control, it positions the new one at the mouse position
  //and disable drop new control mode. The new control should be in selected state.
  if UnitopPallet.NewPFDControl <> nil then begin
    with UnitopPallet.NewPFDControl do begin
      Left := X - Width;
      Top := Y - Height;
      Scale := 1;
      DrawWireFrame := False;
      Selected := True;
    end;//with
    UnitopPallet.NewPFDControl := nil;
    //Return cursor to default state.
    Cursor := crDefault;
  end;//if
end;

procedure TPFDWorkplace.MouseEnter;
begin
  inherited MouseEnter;
  //Debugln('TPFDWorkplace.MouseEnter');
  if UnitopPallet.NewPFDControl <> nil then
    UnitopPallet.NewPFDControl.Visible := True;
end;

procedure TPFDWorkplace.MouseLeave;
begin
  inherited MouseLeave;
  //Debugln('TPFDWorkplace.MouseLeave');
  EraseGuideLines;
  if UnitopPallet.NewPFDControl <> nil then
    UnitopPallet.NewPFDControl.Visible := False;
end;

procedure TPFDWorkplace.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  
  //Debugln(ClassName,': MouseMove');
  
  //These mouse move event can be triggered after a window maximization.
  //In this case, the event should be ignored to avoid staining the canvas.
  if Resized then begin
    Resized := False;
    Exit;
  end;//if
  
  //Changes the cursor to indicate a PFD control can be dropped.
  //Guidelines should not show while in dropping mode for a new control.
  if UnitopPallet.NewPFDControl <> nil then begin
    //if Cursor <> crCross then
    // Cursor := crCross;
    EraseGuideLines;
    //Positions the new control at the mouse pointer.
    with UnitopPallet.NewPFDControl do begin
      SetBounds(X - Width, Y - Height, Width, Height);
    end;//with
  end
  else begin
    ResetGuideLines;
  end;//if
  
end;

procedure TPFDWorkplace.MouseUp(Button: TMouseButton ; Shift: TShiftState; X, 
        Y: Integer);
var
  I: Integer;
  Delta, Origin: TPoint;
  R: TRect;
begin
  inherited MouseUp(Button, Shift, X, Y);
  
  //Debugln('TPFDWorkplace.MouseUp(Button: %s ; Shift: %s; X, Y: %s, %s', ['0', '0', IntToStr(X), IntToStr(Y)]);
  
  //We need to remove the guidelines to prevent interference with the control
  //repaint, which could cause staining on the canvas.
  EraseGuideLines;
  
  //If finishing a dragging operation, move the selected controls for the new position.
  if (DragControl <> nil) and
     (DragControl is TPFDControl) then begin
  
    with TPFDControl(DragControl) do
      Origin := Self.ScreenToClient(ClientToScreen(StartDragPoint));
  
    Delta.X := Self.ScreenToClient(Mouse.CursorPos).X - Origin.X;
    Delta.Y := Self.ScreenToClient(Mouse.CursorPos).Y - Origin.Y;
    for I := 0 to ControlCount - 1 do
      if  (Controls[I] is TPFDControl) then
        with TPFDControl(Controls[I]) do
          if Selected then begin
            //Place the control on the new position at once.
            SetBounds(Left + Delta.X, Top + Delta.Y, Width, Height);
            //We must allow application to process paint messages so the
            //repaiting is finished before the guidelines are drawn again.
            //Tried to use Invalidate method, but causes staining.
            Application.ProcessMessages;
          end;//if
  
    //Set nil to indicate there is no dragged control anymore.
    DragControl := nil;
  
  end;//if
  
  //Redraw the lines.
  DrawGuideLines;
end;

procedure TPFDWorkplace.Paint;
begin
  inherited Paint;
  //It is necessary to draw the background on Linux, because TScrollbox is
  //not painted with the correct color.
  //with Canvas do begin
    //Pen.Style := psClear;
    //Brush.Style := bsSolid;
    //Brush.Color := $00808040;
    //Rectangle(ClientRect);
  //end;//with
end;

procedure TPFDWorkplace.PaintDragFrames(Origin, Dest: TPoint);
var
  I: Integer;
  Delta: TPoint;
  R: TRect;
begin
  Delta.X := Dest.X - Origin.X;
  Delta.Y := Dest.Y - Origin.Y;
  for I := 0 to ControlCount - 1 do
    if  (Controls[I] is TPFDControl) and
        (TPFDControl(Controls[I]).Selected) then begin
      R := TPFDControl(Controls[I]).BoundsRect;
      with Canvas do begin
        Pen.Color := clRed;
        Pen.Mode := pmNot;
        Pen.Style := psSolid;
        Brush.Style := bsClear;
        Rectangle(Rect(R.Left+Delta.X, R.Top+Delta.Y, R.Right+Delta.X-1, R.Bottom+Delta.Y-1));
      end;//with
    end;//if
end;

procedure TPFDWorkplace.ResetGuideLines;
begin
  EraseGuideLines;
  DrawGuideLines;
end;

procedure TPFDWorkplace.Resize;
begin
  inherited Resize;
  //Set the flag to indicate that a resize operation occured.
  Resized := True;
end;

procedure TPFDWorkplace.WMKillFocus(var Message: TLMKillFocus);
begin
  inherited WMKillFocus(Message);
  //DebugLn('TWinControl.WMKillFocus A ',Name,':',ClassName);
end;

procedure TPFDWorkplace.WMSetFocus(var Message: TLMSetFocus);
begin
  inherited WMSetFocus(Message);
  //DebugLn('TWinControl.WMSetFocus A ',Name,':',ClassName);
end;

end.
