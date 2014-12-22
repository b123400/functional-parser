{Parser, Lexer} = require './parser'
LineStep = require './syntax/line'
SettingStep = require './syntax/setting'
CharacterStep = require './syntax/character'
EmotionStep = require './syntax/emotion'

Jison = require 'jison'

parser = new Parser

characterStep = new CharacterStep ['Alice', 'Bob']
parser.addSyntax characterStep

emotionStep = new EmotionStep
parser.addSyntax emotionStep

settingStep = new SettingStep (key, values)->
  characterStep.applySetting key, values

parser.addSyntax settingStep

lineStep = new LineStep
parser.addSyntax lineStep

result = parser.parse """
-- Characters : Alice, Bob, Chris --
Long long time ago, there were 3 people.

Alice: Good morning.
Chris: Hello.
Bob(Smile): :)

Note: This line is not considered as speech.

Alice (Wave, Smile) : Bye
"""
console.log JSON.stringify result