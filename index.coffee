class Lexer
  constructor : ->
    @steps = []
    @setInput ""

  addLexingStep : (lexingStep)->
    @steps.push lexingStep if lexingStep not in @steps
    lexingStep.lexer = @

  setInput : (@input)=>
    @yytext = ""
    @index = 0
    @tokens = []
    @queue = []

  lex : =>
    if queued = @dequeue()
      return queued.token

    currentText = @remainingText()
    return "EOF" if not currentText
    
    for step in @steps
      thisToken = step.lexingStep currentText
      continue if not thisToken
      
      capturedText = step.yytext
      if thisToken not instanceof Array
        thisToken = [thisToken]
        capturedText = [capturedText]

      objs = ({ token, text:capturedText[index] } for token, index in thisToken)
      @queue.push obj for obj in objs

      return @dequeue().token
    return 'INVALID'

  dequeue : =>
    return false if not @queue.length
    thisObj = @queue.shift()
    @yytext = thisObj.text
    @index += @yytext.length
    @tokens.push thisObj.token
    return thisObj

  remainingText : =>
    @input.substr @index

class RegexStep
  ###
  # @param regex {Regex}
  # @param callback {RegexLexer~callback}
  #
  ###

  ###
  # @callback RegexLexer~callback
  # @param matchedText
  # @return tokenName
  ###
  constructor: (@regex, @callback)->
  lexingStep : (text)->
    match = @regex.exec(text)
    return false if not match or match.index isnt 0
    matchText = match[0]
    @yytext = matchText
    return @callback.call @, match

class LineStep
  constructor : (@name='LINE')->
  lexingStep : (input)->
    firstLineBreak = input.indexOf '\n'
    if firstLineBreak isnt -1
      @yytext = input.substr 0, firstLineBreak+1
    else
      @yytext = input
    return @name

class BaseStep
  lastToken : -> @lexer.tokens[-1..][0]

class CharacterStep extends BaseStep
  colonRegex : /[\s]*:[\s]*/
  constructor : (@characters=[])->
    super

  addCharacter : (name)->
    @characters.push name if name not in @characters

  lexingStep : (input)->
    if @lastToken() is 'CHARACTER_NAME'
      # Character name followed by a colon
      # [Character name] : some text
      nextColon = @colonRegex.exec input
      if nextColon?.index is 0
        @yytext = nextColon[0]
        return ':'

    for characterName in @characters
      if input.substr(0, characterName.length) is characterName
        @yytext = characterName

        return 'CHARACTER_NAME'
    return false

class EmotionStep extends BaseStep
  regex :
    open  : /[\s]*\([\s]*/
    close : /[\s]*\)[\s]*/
    comma : /[\s]*,[\s]*/
    string : /[^,\(\)]+/

  constructor : ->
    super
    @openStep = new RegexStep @regex.open, -> '('
    @closeStep = new RegexStep @regex.close, -> ')'
    @commaStep = new RegexStep @regex.comma, -> ','
    @stringStep = new RegexStep @regex.string, -> 'EMOTION_NAME'
    @subLexer = new Lexer
    @subLexer.addLexingStep s for s in [@openStep, @closeStep, @commaStep, @stringStep]

  lexingStep : (input)->
    return false if @lastToken() isnt 'CHARACTER_NAME'
    
    @subLexer.setInput input

    results = []
    while lexed = @subLexer.lex()
      # console.log "lexed: #{lexed}, and yytext: #{@subLexer.yytext}"
      if lexed is 'INVALID'
        return false
      else
        results.push {lexed, yytext:@subLexer.yytext}
        break if lexed is ')'

    return false if results.length is 0

    # Try character colon here because we overrided it
    colonMatch = CharacterStep::colonRegex.exec @subLexer.remainingText()
    if colonMatch?.index is 0
      results.push
        lexed : ':'
        yytext : colonMatch[0]

    @yytext = (r.yytext for r in results)
    return (r.lexed for r in results)

    # emotionMatch = emotionRegex.exec input
    # if emotionMatch?.index is 0
    #   [ captured, open, name, end ] = emotionMatch
    #   @yytext = [ open, name, end ]
    #   return ['(','EMOTION_NAME',')']
    # return false

class SettingStep
  regex:
    dash : /[\s]*-+[\s]*/
    string : /[^:\s,]+/
    # key : /([^:\s]+)\s*:/
    # value : /(.+?)\s*-+/
    comma : /[\s]*,[\s]*/
    colonRegex : /[\s]*:[\s]*/

  constructor : (@callback)->
    @dashStep = new RegexStep @regex.dash, -> '-'
    @stringStep = new RegexStep @regex.string, -> 'SETTING_STRING'
    @commaStep = new RegexStep @regex.comma, -> ','
    @colonStep = new RegexStep @regex.colonRegex, -> ':'

    @subLexer = new Lexer
    @subLexer.addLexingStep s for s in [@dashStep, @colonStep, @commaStep, @stringStep]
  lexingStep : (input)->

    @subLexer.setInput input

    results = []
    i = 0
    dashCount = 0
    while lexed = @subLexer.lex()

      break if i is 0 and lexed isnt '-'
      break if lexed is 'INVALID'

      results.push {lexed, yytext:@subLexer.yytext}

      dashCount++ if lexed is '-'
      break if dashCount is 2
      i++

    return false if results.length is 0

    @yytext = (r.yytext for r in results)
    return (r.lexed for r in results)
    
    # thisLine = 
    #   if lineBreakIndex isnt -1
    #   then input.substr 0, lineBreakIndex
    #   else input
    
    # if not (thisLine.substr(0,2) ==  thisLine.substr(-2) == "--")
    #   return false
    
    # [key, valueString] = thisLine.split ':'

    # if not key or not valueString
    #   throw 'Needs a colon in setting'

    # key = key.substr 2
    # valueString = valueString.substr 0, valueString.length-2

    # key = key.replace /\s/g, ''
    # values = valueString.split ','
    # values = (v.replace /\s/g, '' for v in values)
    
    # if values.length is 1
    #   values = values[0]

    # @callback? key, values
    # @yytext = thisLine
    # return 'SETTING'

lexer = new Lexer

number = new RegexStep /[0-9]+/, ->'NUMBER'
lexer.addLexingStep number

characterStep = new CharacterStep ['Alice', 'Bob', 'Chris']
lexer.addLexingStep characterStep

emotionStep = new EmotionStep
lexer.addLexingStep emotionStep

settingStep = new SettingStep (key, value)->
  if key.toLowerCase() is 'characters'
    if value instanceof Array
      characterStep.addCharacter v for v in value
    else
      characterStep.addCharacter value

lexer.addLexingStep settingStep

lineStep = new LineStep 'SPEECH'
lexer.addLexingStep lineStep

# lexer.setInput """
# -- Characters : Alice, Bob, Chris --
# Long long time ago, there were 3 people.

# Alice: Good morning.
# Chris: Hello.
# Bob(Smile): :)

# Note: This line is not considered as speech.

# Alice (Wave, Smile) : Bye
# """

# while output = lexer.lex()
#   console.log "token=#{output}, text=#{lexer.yytext}"
#   break if output is "EOF"

Jison = require 'jison'

grammar = {
    "operators": [
        ["left", ":"]
    ]

    "bnf": {
        "expressions" :[[ "LINES EOF",   "console.log($1); console.log('hello is '+yy.hello); return $1;"  ]]

        "LINES" : [
          [ "LINE" , "$$ = [$1]" ]
          [ "LINES LINE", "$1.push($2)" ]
        ]

        "LINE" : [
          [ "SETTING", "$$ = $1"]
          [ "SPEECH", "$$ = {speech:$1}"]
          [ "CHARACTER", "$$ = {character:$1}" ]
          [ "CHARACTER : SPEECH", "$$ = {character:$1, speech:$3}"]
        ]

        "CHARACTER" : [
          [ "CHARACTER_NAME", "$$ = {name:$1}"],
          [ "CHARACTER_NAME ( EMOTION_NAME_LIST )", "$$ = {name:$1, emotion:$3}" ]
        ]

        "EMOTION_NAME_LIST" : [
          ["EMOTION_NAME", "$$ = [$1]"]
          ["EMOTION_NAME_LIST , EMOTION_NAME", "$1.push($3)"]
        ]

        "SETTING" : [
          [ "- SETTING_KEY : SETTING_VALUE -", " $$ = {}; $$[$2] = $4;"]
        ]

        "SETTING_KEY" : [
          [ "SETTING_STRING", "$$ = $1" ]
        ]

        "SETTING_VALUE" : [
          [ "SETTING_STRING", "$$ = [$1]" ]
          [ "SETTING_VALUE , SETTING_STRING", "$1.push($3)"]
        ]

        # "LINE" :[[ "e + e",   "$$ = $1 + $3;" ],
        #       [ "e - e",   "$$ = $1 - $3;" ],
        #       [ "e * e",   "$$ = $1 * $3;" ],
        #       [ "e / e",   "$$ = $1 / $3;" ],
        #       [ "e ^ e",   "$$ = Math.pow($1, $3);" ],
        #       [ "- e",     "$$ = -$2;", {"prec": "UMINUS"} ],
        #       [ "( e )",   "$$ = $2;" ],
        #       [ "NUMBER",  "$$ = Number(yytext);" ],
        #       [ "E",       "$$ = Math.E;" ],
        #       [ "PI",      "$$ = Math.PI;" ]]
    }
}

parser = new Jison.Parser grammar
parser.yy = {hello:'outside'}
parser.lexer = lexer
__original = lexer.lex
lexer.lex = ->
  result = __original.apply @, arguments
  return result
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