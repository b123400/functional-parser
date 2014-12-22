Jison = require 'jison'
fs = require 'fs'

class Lexer
  constructor : ->
    @syntaxes = []
    @setInput ""

  addSyntax : (syntax)->
    @syntaxes.push syntax if syntax not in @syntaxes
    syntax.lexer = @

  setInput : (@input)=>
    @yytext = ""
    @index = 0
    @tokens = []
    @queue = []

  lex : =>
    if queued = @dequeue()
      return queued.token

    currentText = @remainingText()
    if not currentText
      return "EOF"
    
    for syntax in @syntaxes
      thisToken = syntax.lexingStep currentText
      continue if not thisToken
      
      capturedText = syntax.yytext
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

class Parser
  constructor : ->
    @bnf = {
      FILE: [
        ['STATES EOF', 'console.log($1); return $1']
      ]

      STATES: [
        ['STATE', '$$ = [$1]']
        ['STATES STATE', 'if($2)$1.push($2)']
      ]
    }
    @lexer = new Lexer
    @yy = {}

  addGrammar : (fn)->
    tokens = fn? @bnf
    for token, value of tokens
      if token of @bnf
        @bnf[token] = @bnf[token].concat value
      else
        @bnf[token] = value

  addSyntax : (syntax)->
    @lexer.addSyntax syntax
    @addGrammar syntax.grammar?.bind?(syntax)
    bridge = syntax.bridge?()
    for key, fn of bridge
      @yy[key] = fn

  parse : (text)->
    grammar =
      bnf : @bnf
      operators: [
          ["left", ":"]
      ]

    parser = new Jison.Parser grammar
    parser.yy = @yy
    parser.lexer = @lexer
    js = parser.generate();
    fs.writeFileSync './wowowow.js', js
    parser.parse text

module.exports = {Lexer, Parser}