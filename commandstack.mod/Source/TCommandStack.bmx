Rem
'
' Copyright (c) 2009-2013 Paul Maskelyne <muttley@muttleyville.org>.

' All rights reserved. Use of this code is allowed under the
' Artistic License 2.0 terms, as specified in the LICENSE file
' distributed with this code, or available from
' http://www.opensource.org/licenses/artistic-license-2.0.php
'
EndRem

Rem
	bbdoc: Command Stack class
	about: The command stack manages the running of application commands, where
	possible adding completed commands to undo/redo stacks.  This allows you to
	provide unlimited undo/redo level support to your applications.
EndRem
Type TCommandStack

	Const INITIAL_STACK_SIZE:Int = 10
	Const STACK_GROW_SIZE:Int    = 10

	' A macro command that can be recorded to
	Field _macroToRecordTo:TMacroCommand

	' Whether a macro is being recorded or not
	Field _macroRecording:Int

	' Stack of commands that can be redone
	Field _redoCommands:TStack

	' Used to inform the application whether there are unsaved changes made
	Field _undoCommandCountAtLastSave:Int

	' Stack of commands that can be undone
	Field _undoCommands:TStack


	Rem
		bbdoc: Adds the command to the command stack and issues the command.
		about: If the command runs successfully and can be undone, it will be added
		to the undo list.  If it ran OK but can't be undone both the undo and redo
		stacks are cleared and the command is not added to the undo stack.
	EndRem
	Method AddCommand (command:TCommand)
		If _macroRecording
			If Not _macroToRecordTo Then _macroToRecordTo = New TMacroCommand
			_macroToRecordTo.AddCommand (command.Copy())
		End If

		If command.Execute()
			If command.CanBeUndone()
				AppendCommand (command)
			Else
				'This command cannot be undone, so clear the stacks - we don't need them any more
				ClearStacks()
			End If
		End If
	End Method



	Rem
		bbdoc: Appends the command to the stack, merging where possible
	EndRem
	Method AppendCommand (command:TCommand)
		' We can't redo anything having just done something so clear the redo stack
		_redoCommands.Clear()

		If _undoCommandCountAtLastSave > UndoCount()
			' We can't undo to get to the last saved state
			_undoCommandCountAtLastSave = -1
		End If

		' Attempts to merge with the command on the top of the stack.
		If UndoCount() = 0 Or Not TCommand (_undoCommands.Peek()).Merge (command)
			' Commands can't be merged so we push it onto the top of the stack
			_undoCommands.Push (command)
		EndIf
	End Method



	Rem
		bbdoc: Return whether there are commands available to redo or not
		returns: True if redo is available, otherwise False
	EndRem
	Method CanRedo:Int()
		Return RedoCount() > 0
	End Method



	Rem
		bbdoc: Return whether there are commands available to undo or not
		returns: True if undo is available, otherwise False
	EndRem
	Method CanUndo:Int()
		Return UndoCount() > 0
	End Method



	Rem
		bbdoc: Clears the undo and redo stacks
	EndRem
	Method ClearStacks()
		_undoCommands.Clear()
		_redoCommands.Clear()

		' We can't undo to get to the last saved state
		_undoCommandCountAtLastSave = -1
	End Method



	Rem
		bbdoc: Return whether the application is dirty or not
		returns: True if the application is dirty, otherwise False
		about: The application is classed as dirty if they number of undo commands
		in the stack is different to the number the last time we were notified of
		a save.
	EndRem
	Method IsDirty:Int()
		Return _undoCommandCountAtLastSave <> UndoCount()
	End Method



	Rem
		bbdoc: Default constructor
	EndRem
	Method New()
		_undoCommands = TStack.Create (INITIAL_STACK_SIZE, STACK_GROW_SIZE)
		_redoCommands = TStack.Create (INITIAL_STACK_SIZE, STACK_GROW_SIZE)
		_undoCommandCountAtLastSave = 0
		_macroRecording = False
	End Method



	Rem
		bbdoc: Notify the command stack that the application has saved
		about: This updates the counter used to determine whether the application is
		dirty or not.
	EndRem
	Method ProgressSaved()
		_undoCommandCountAtLastSave = UndoCount()
	End Method




	Rem
		bbdoc: Attempts to redo the top command on the redo stack
	EndRem
	Method Redo()
		If CanRedo()
			Local command:TCommand = TCommand (_redoCommands.Pop())
			command.Execute()
			_undoCommands.Push (command)
		End If
	End Method



	Rem
		bbdoc: Get the number of commands in the redo stack
	EndRem
	Method RedoCount:Int()
		Return _redoCommands.GetCount()
	End Method



	Rem
		bbdoc: Tells the command stack to start recording executed commands into
		a macro command
		about: Will not start recording if there is already a recording in progress
	EndRem
	Method StartRecordingMacro()
		If Not _macroRecording
			_macroRecording = True
			_macroToRecordTo = New TMacroCommand
		End If
	End Method



	Rem
		bbdoc: Tells the command stack top stop recording executed commnds into
		a macro command
		returns: A TMacroCommand instance holding all the commands executed during recording
	EndRem
	Method StopRecordingMacro:TMacroCommand()
		Local macroCommand:TMacroCommand = Null
		If _macroRecording
			_macroRecording = False
			macroCommand = _macroToRecordTo
		End If
		Return macroCommand
	End Method



	Rem
		bbdoc: Attempts to undo the top command on the redo stack
	EndRem
	Method Undo()
		If CanUndo()
			Local command:TCommand = TCommand (_undoCommands.Pop())
			command.Unexecute()
			_redoCommands.Push(command)
		End If
	End Method



	Rem
		bbdoc: Get the number of commands in the undo stack
	EndRem
	Method UndoCount:Int()
		Return _undoCommands.GetCount()
	End Method

End Type
