// Generated by CoffeeScript 1.7.1
var RegexSyntax;

RegexSyntax = (function() {

  /*
   * @param regex {Regex}
   * @param callback {RegexLexer~callback}
   *
   */

  /*
   * @callback RegexLexer~callback
   * @param matchedText
   * @return tokenName
   */
  function RegexSyntax(regex, callback) {
    this.regex = regex;
    this.callback = callback;
  }

  RegexSyntax.prototype.lexingStep = function(text) {
    var match, matchText;
    match = this.regex.exec(text);
    if (!match || match.index !== 0) {
      return false;
    }
    matchText = match[0];
    this.yytext = matchText;
    return this.callback.call(this, match);
  };

  RegexSyntax.prototype.grammar = function() {
    throw 'Override me';
  };

  return RegexSyntax;

})();

module.exports = RegexSyntax;
