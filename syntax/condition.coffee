BaseSyntax = require './base'
RegexSyntax = require './regex'
{Lexer} = require '../parser'

class ConditionSyntax extends BaseSyntax
  regex :
    open : /[\s]*\[[\s]*/
    close : /[\s]*->\][\s]*/
    value : /[^\s\[\]]+/

  constructor : ->
    super
    @openSyntax = new RegexSyntax @regex.open, -> '['
    @closeSyntax = new RegexSyntax @regex.close, -> '->]'
    @valueSyntax = new RegexSyntax @regex.value, -> 'CONDITION_VALUE'
    @subLexer = new Lexer
    @subLexer.addSyntax s for s in [@openSyntax, @closeSyntax, @valueSyntax]

  lexingStep : (input)->
    @subLexer.setInput input
    
    yytexts = []
    tokens = []
    i = 0
    while lexed = @subLexer.lex()
      break if lexed is 'INVALID' or lexed is 'EOF'

      yytexts.push @subLexer.yytext
      tokens.push lexed

      break if lexed is '->]'
      i++

    return false if tokens.length is not 3
    [open, value, close] = tokens
    return false if open isnt '[' or value isnt 'CONDITION_VALUE' or close isnt '->]'

    @yytext = yytexts
    return tokens

  grammar : ->
    STATE : [
      @pattern 'CONDITION STATE', -> $2.condition = $1; $2
    ]

    CONDITION : [
      @pattern '[ CONDITION_VALUE ->]', -> $2
    ]

module.exports = ConditionSyntax