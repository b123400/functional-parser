BaseSyntax = require './base'
RegexSyntax = require './regex'
CharacterSyntax = require './character'
{Lexer} = require '../parser'

class EmotionSyntax extends BaseSyntax
  regex :
    open  : /[\s]*\([\s]*/
    close : /[\s]*\)[\s]*/
    comma : /[\s]*,[\s]*/
    string : /[^,\(\)]+/

  constructor : ->
    super
    @openSyntax = new RegexSyntax @regex.open, -> '('
    @closeSyntax = new RegexSyntax @regex.close, -> ')'
    @commaSyntax = new RegexSyntax @regex.comma, -> ','
    @stringSyntax = new RegexSyntax @regex.string, -> 'EMOTION_NAME'
    @subLexer = new Lexer
    @subLexer.addSyntax s for s in [@openSyntax, @closeSyntax, @commaSyntax, @stringSyntax]

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
    colonMatch = CharacterSyntax::colonRegex.exec @subLexer.remainingText()
    if colonMatch?.index is 0
      results.push
        lexed : ':'
        yytext : colonMatch[0]

    @yytext = (r.yytext for r in results)
    return (r.lexed for r in results)

  grammar : ->
    CHARACTER : [
      @pattern "CHARACTER_NAME ( EMOTION_NAME_LIST )", -> {name:$1, emotions:$3}
    ]

    "EMOTION_NAME_LIST" : [
      @pattern "EMOTION_NAME", -> [$1]
      @pattern "EMOTION_NAME_LIST , EMOTION_NAME", -> $1.concat $3
    ]

module.exports = EmotionSyntax