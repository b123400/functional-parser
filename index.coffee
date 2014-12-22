{Parser, Lexer} = require './parser'
LineSyntax = require './syntax/line'
SettingSyntax = require './syntax/setting'
CharacterSyntax = require './syntax/character'
EmotionSyntax = require './syntax/emotion'
ConditionSyntax = require './syntax/condition'

Jison = require 'jison'

parser = new Parser

characterSyntax = new CharacterSyntax ['Alice', 'Bob']
parser.addSyntax characterSyntax

emotionSyntax = new EmotionSyntax
parser.addSyntax emotionSyntax

settingSyntax = new SettingSyntax (key, values)->
  characterSyntax.applySetting key, values

parser.addSyntax settingSyntax

parser.addSyntax new ConditionSyntax

lineSyntax = new LineSyntax
parser.addSyntax lineSyntax

result = parser.parse """
-- Characters : Alice, Bob, Chris --
Long long time ago, there were 3 people.

Alice: Good morning.
Chris: Hello.
Bob(Smile): :)

Note: This line is not considered as speech.

Alice (Wave, Smile) : Bye
[Condition ->]move!
"""
console.log JSON.stringify result