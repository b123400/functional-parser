BaseSyntax = require './base'

class LineSyntax extends BaseSyntax
  constructor : (@name='LINE', @attribute='text')->
  lexingStep : (input)->
    firstLineBreak = input.indexOf '\n'
    if firstLineBreak isnt -1
      @yytext = input.substr 0, firstLineBreak+1
    else
      @yytext = input
    return @name

  grammar : (bnf)->
    STATE : [
      [@name, "$$ = {#{@attribute} : $1}"]
    ]

module.exports = LineSyntax