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
    super
    @dashSyntax = new RegexSyntax @regex.dash, -> '-'
    @stringSyntax = new RegexSyntax @regex.string, -> 'SETTING_STRING'
    @commaSyntax = new RegexSyntax @regex.comma, -> ','
    @colonSyntax = new RegexSyntax @regex.colonRegex, -> ':'

    @subLexer = new Lexer
    @subLexer.addSyntax s for s in [@dashSyntax, @colonSyntax, @commaSyntax, @stringSyntax]
  lexingStep : (input)->
    @subLexer.setInput input

    results = []
    yytexts = []
    i = 0
    dashCount = 0
    while lexed = @subLexer.lex()

      break if lexed is 'INVALID' or lexed is 'EOF'

      results.push lexed
      yytexts.push @subLexer.yytext

      dashCount++ if lexed is '-'
      break if dashCount is 2
      i++

    return false if results.length is 0
    [open, middle..., close] = results
    return false if open isnt '-' or close isnt '-' or not middle.every (x)-> x in ['SETTING_STRING', ':', ',']

    @yytext = yytexts
    return results

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