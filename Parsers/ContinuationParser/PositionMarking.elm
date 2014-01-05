{-
Copyright info at end of file
-}
module Parsers.ContinuationParser.PositionMarking where
{-|
This file provides the basic functionality for generating error messages with line number and column markings.

# Types
@docs PositionMarked

# Constants
@docs standardTaker, standardTakerOptions

# Functions
@docs charsToPositionMarkedChars, handlePositionMarkedInput, parseErrorAt, parseErrorAts, errorAt, errorAts, markEndOfInputAsErrorAt, markEndOfInputAsError

-}
import open Parsers.ContinuationParser
import open Parsers.ContinuationParser.Types
import open Parsers.ContinuationParser.Take
import open Parsers.ContinuationParser.LexemeEaters

type PositionMarked char =
 {line: Int
 ,column: Int
 ,char: char}

standardTakerOptions: TakerOptions char (PositionMarked char) output
standardTakerOptions =
 {lexemeEaterTransform = handlePositionMarkedInput
 ,inputTransform = unmark}

standardTaker: Taker char (PositionMarked char) intermediate output
standardTaker = newTaker standardTakerOptions

charsToPositionMarkedChars: [Char] -> [PositionMarked Char]
charsToPositionMarkedChars chars = (\(acc,_,_) -> reverse acc) <|  foldl charToPositionMarkedChar ([],0,0) chars
charToPositionMarkedChar char (acc,line,col) =
    if | char == '\n' -> ({line=line,column=col,char=char} :: acc,line+1,0)
       | otherwise ->    ({line=line,column=col,char=char} :: acc,line,col+1)

unmark: [PositionMarked char] -> [char]
unmark = map (.char)

handlePositionMarkedInput: LexemeEater char output -> LexemeEater (PositionMarked char) output
handlePositionMarkedInput
 = anotateError (\err acc input -> errorAt err input)
 . convertInput (\i->i.char)

parseErrorAt: String -> PositionMarked char -> ParserResult input output
parseErrorAt message location = ParseError <| errorAt message location

parseErrorAts: String -> [PositionMarked char] -> ParserResult input output
parseErrorAts message input = ParseError <| errorAts message input

errorAt: String -> PositionMarked char -> String
errorAt message location =
 message ++ "\n    On line:"++(show location.line)
         ++ "\n    At column:"++(show location.column)

errorAts: String -> [PositionMarked char] -> String
errorAts message input =
 case input of
  (location::_) -> errorAt message location
  [] -> message ++ "\n    At end of input"

markEndOfInputAsErrorAt: ContinuationParser (PositionMarked input) intermediate output -> String -> ContinuationParser (PositionMarked input) intermediate output
markEndOfInputAsErrorAt continuationParser message continuation input =
 let
  err = parseErrorAts message input
 in
 (continuationParser `replaceEndOfInputWith` err) continuation input -- Why do I need those parens?

{-
The continuation parser
Parsec inspired continuation passing style parser

Copyright (C) 2013  Timothy Hobbs <timothyhobbs@seznam.cz> thobbs.cz

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 3.0 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library.
-}