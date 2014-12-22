class BaseSyntax
  lastToken : ->
    @lexer.tokens[-1..][0]
  
  pattern: (pattern, action, options={})->
    if pattern[-4..] is " EOF"
      [pattern, "return (#{action})();", options]
    else
      [pattern, "$$ = (#{action})();", options]

module.exports = BaseSyntax