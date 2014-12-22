BaseSyntax = require './base'
RegexSyntax = require './regex'
{Lexer} = require '../parser'

class SettingSyntax extends BaseSyntax
  regex:
    dash : /[\s]*-+[\s]*/
    string : /[^:\s,]+/
    # key : /([^:\s]+)\s*:/
    # value : /(.+?)\s*-+/
    comma : /[\s]*,[\s]*/
    colonRegex : /[\s]*:[\s]*/

  constructor : (@callback)->
    @dashSyntax = new RegexSyntax @regex.dash, -> '-'
    @stringSyntax = new RegexSyntax @regex.string, -> 'SETTING_STRING'
    @commaSyntax = new RegexSyntax @regex.comma, -> ','
    @colonSyntax = new RegexSyntax @regex.colonRegex, -> ':'

    @subLexer = new Lexer
    @subLexer.addSyntax s for s in [@dashSyntax, @colonSyntax, @commaSyntax, @stringSyntax]
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

  grammar : (bnf)->
    STATE : [
      @pattern "SETTING", -> $1
    ]

    SETTING : [
      @pattern "- SETTING_KEY : SETTING_VALUE -", ->
        obj={}
        key=$2
        obj[key]=$4
        yy.receivedSetting $2, $4
        return obj
    ]

    SETTING_KEY : [
      @pattern "SETTING_STRING", -> $1
    ]

    SETTING_VALUE : [
      @pattern "SETTING_STRING", -> [$1]
      @pattern "SETTING_VALUE , SETTING_STRING", -> $1.concat $3
    ]

  bridge : ->
    receivedSetting : (key, values)=>
      @callback? key, values

module.exports = SettingSyntax