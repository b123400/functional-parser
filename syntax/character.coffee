BaseSyntax = require './base'

class CharacterSyntax extends BaseSyntax
  colonRegex : /[\s]*:[\s]*/
  constructor : (@characters=[])->
    super

  addCharacter : (name)->
    @characters.push name if name not in @characters

  lexingStep : (input)->
    if @lastToken() is 'CHARACTER_NAME'
      # Character name followed by a colon
      # [Character name] : some text
      nextColon = @colonRegex.exec input
      if nextColon?.index is 0
        @yytext = nextColon[0]
        return ':'

    for characterName in @characters
      if input.substr(0, characterName.length) is characterName
        @yytext = characterName

        return 'CHARACTER_NAME'
    return false

  grammar : ->
    STATE : [
      @pattern "CHARACTER", -> {character:$1}
      @pattern "CHARACTER : LINE", -> {character:$1, speech:$3}
    ]

    "CHARACTER" : [
      @pattern "CHARACTER_NAME", -> {name:$1}
    ]

  applySetting : (key, values)->
    return if key.toLowerCase() isnt 'characters'
    @addCharacter v for v in values

module.exports = CharacterSyntax