// Generated by CoffeeScript 1.7.1
var BaseSyntax;

BaseSyntax = (function() {
  function BaseSyntax() {}

  BaseSyntax.prototype.lastToken = function() {
    return this.lexer.tokens.slice(-1)[0];
  };

  BaseSyntax.prototype.pattern = function(pattern, action, options) {
    if (options == null) {
      options = {};
    }
    if (pattern.slice(-4) === " EOF") {
      return [pattern, "return (" + action + ")();", options];
    } else {
      return [pattern, "$$ = (" + action + ")();", options];
    }
  };

  return BaseSyntax;

})();

module.exports = BaseSyntax;
