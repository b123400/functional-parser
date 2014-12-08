class Lexer
  constructor : ->
    @steps = []
    @setInput ""

  addLexingStep : (lexingStep)->
    @steps.push lexingStep if lexingStep not in @steps
    lexingStep.lexer = @

  setInput : (@input)->
    @yytext = ""
    @index = 0
    @tokens = []
    @queue = []

  lex : ->
    if queued = @dequeue()
      return queued.token

    currentText = @remainingText()
    return if not currentText
    
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

  dequeue : ->
    return false if not @queue.length
    thisObj = @queue.shift()
    @yytext = thisObj.text
    @index += @yytext.length
    @tokens.push thisObj.token
    return thisObj

  remainingText : ->
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
        return 'COLON'

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
      console.log "lexed: #{lexed}, and yytext: #{@subLexer.yytext}"
      if lexed is 'INVALID'
        break
      else
        results.push {lexed, yytext:@subLexer.yytext}
        break if lexed is ')'

    return false if results.length is 0

    # Try character colon here because we overrided it
    colonMatch = CharacterStep::colonRegex.exec @subLexer.remainingText()
    if colonMatch?.index is 0
      results.push
        lexed : 'COLON'
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

emotionStep = new EmotionStep
lexer.addLexingStep emotionStep

settingStep = new SettingStep (key, value)->
  if key.toLowerCase() is 'characters'
    if value instanceof Array
      characterStep.addCharacter v for v in value
    else
      characterStep.addCharacter value

lexer.addLexingStep settingStep

lineStep = new LineStep
lexer.addLexingStep lineStep

lexer.setInput """
-- Characters : Alice, Bob, Chris --
Long long time ago, there were 3 people.

Alice: Good morning.
Chris: Hello.
Bob(Smile): :)

Note: This line is not considered as speech.

Alice (Wave, Smile) : Bye
"""

while output = lexer.lex()
  console.log "token=#{output}, text=#{lexer.yytext}"