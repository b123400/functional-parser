BaseSyntax = require './base'

class EmptySyntax extends BaseSyntax
  constructor : ->
  lexingStep : (input)->
    @yytext = input[0]
    return 'EMPTY'

  grammar : (bnf)->
    STATE : [
      @pattern 'EMPTY', -> null
    ]

module.exports = EmptySyntax