class RegexSyntax
  ###
  # @param regex {Regex}
  # @param callback {RegexLexer~callback}
  #
  ###

  ###
  # @callback RegexLexer~callback
  # @param matchedText
  # @return tokenName
  ###
  constructor: (@regex, @callback)->
  lexingStep : (text)->
    match = @regex.exec(text)
    return false if not match or match.index isnt 0
    matchText = match[0]
    @yytext = matchText
    return @callback.call @, match

  grammar : ->
    throw 'Override me'

module.exports = RegexSyntax