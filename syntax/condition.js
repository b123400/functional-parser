// Generated by CoffeeScript 1.7.1
var BaseSyntax, ConditionSyntax, Lexer, RegexSyntax,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BaseSyntax = require('./base');

RegexSyntax = require('./regex');

Lexer = require('../parser').Lexer;

ConditionSyntax = (function(_super) {
  __extends(ConditionSyntax, _super);

  ConditionSyntax.prototype.regex = {
    open: /[\s]*\[[\s]*/,
    close: /[\s]*->\][\s]*/,
    value: /[^\s\[\]]+/
  };

  function ConditionSyntax() {
    var s, _i, _len, _ref;
    ConditionSyntax.__super__.constructor.apply(this, arguments);
    this.openSyntax = new RegexSyntax(this.regex.open, function() {
      return '[';
    });
    this.closeSyntax = new RegexSyntax(this.regex.close, function() {
      return '->]';
    });
    this.valueSyntax = new RegexSyntax(this.regex.value, function() {
      return 'CONDITION_VALUE';
    });
    this.subLexer = new Lexer;
    _ref = [this.openSyntax, this.closeSyntax, this.valueSyntax];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      s = _ref[_i];
      this.subLexer.addSyntax(s);
    }
  }

  ConditionSyntax.prototype.lexingStep = function(input) {
    var close, i, lexed, open, tokens, value, yytexts;
    this.subLexer.setInput(input);
    yytexts = [];
    tokens = [];
    i = 0;
    while (lexed = this.subLexer.lex()) {
      if (lexed === 'INVALID' || lexed === 'EOF') {
        break;
      }
      yytexts.push(this.subLexer.yytext);
      tokens.push(lexed);
      if (lexed === '->]') {
        break;
      }
      i++;
    }
    if (tokens.length === !3) {
      return false;
    }
    open = tokens[0], value = tokens[1], close = tokens[2];
    if (open !== '[' || value !== 'CONDITION_VALUE' || close !== '->]') {
      return false;
    }
    this.yytext = yytexts;
    return tokens;
  };

  ConditionSyntax.prototype.grammar = function() {
    return {
      STATE: [
        this.pattern('CONDITION STATE', function() {
          $2.condition = $1;
          return $2;
        })
      ],
      CONDITION: [
        this.pattern('[ CONDITION_VALUE ->]', function() {
          return $2;
        })
      ]
    };
  };

  return ConditionSyntax;

})(BaseSyntax);

module.exports = ConditionSyntax;