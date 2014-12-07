class Lexer
  constructor : ->
    @steps = []
    @input = ""
    @yytext = ""
    @index = 0

  addLexingStep : (lexingStep)->
    @steps.push lexingStep if lexingStep not in @steps

  setInput : (@input)->
    @index = 0

  lex : ->
    currentText = @input.substr @index
    return if not currentText
    for step in @steps
      thisToken = step.lexingStep currentText
      continue if not thisToken
      @yytext = step.yytext
      @index += @yytext.length
      return thisToken
    return 'INVALID'

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
    return @callback matchText

class LineStep
  constructor : (@name='line')->
  lexingStep : (input)->
    firstLineBreak = input.indexOf '\n'
    if firstLineBreak isnt -1
      @yytext = input.substr 0, firstLineBreak+1
    else
      @yytext = input
    return @name

class CharacterStep
  constructor : (@characters=[])->

  addCharacter : (name)->
    @characters.push name if name not in @characters

  lexingStep : (input)->
    for characterName in @characters
      if input.substr(0, characterName.length) is characterName
        @yytext = characterName
        return 'CHARACTER'
    return false

class SettingStep

  constructor : (@callback)->

  lexingStep : (input)->
    lineBreakIndex = input.indexOf '\n'
    
    thisLine = 
      if lineBreakIndex isnt -1
      then input.substr 0, lineBreakIndex
      else input
    
    if not (thisLine.substr(0,2) ==  thisLine.substr(-2) == "--")
      return false
    
    [key, valueString] = thisLine.split ':'

    if not key or not valueString
      throw 'Needs a colon in setting'

    key = key.substr 2
    valueString = valueString.substr 0, valueString.length-2

    key = key.replace /\s/g, ''
    values = valueString.split ','
    values = (v.replace /\s/g, '' for v in values)
    
    if values.length is 1
      values = values[0]

    @callback? key, values
    @yytext = thisLine
    return 'SETTING'

lexer = new Lexer

number = new RegexStep /[0-9]+/, ->'NUMBER'
lexer.addLexingStep number

characterStep = new CharacterStep ['Alice', 'Bob']
lexer.addLexingStep characterStep

settingStep = new SettingStep (key,value)->
  console.log "Setting #{key} = #{value}"
lexer.addLexingStep settingStep

lineStep = new LineStep
lexer.addLexingStep lineStep

lexer.setInput """
-- Characters : Alice, Bob, Chris --
Alice: Wow
"""

while output = lexer.lex()
  console.log output
  console.log lexer.yytext