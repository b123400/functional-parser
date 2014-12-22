BaseSyntax = require './base'

class CharacterSyntax extends BaseSyntax
  colonRegex : /[\s]*:[\s]*/
  constructor : (@characters=[])->
    super

  addCharacter : (name)->
    @characters.push name if name not in @characters

  lexingStep : (input)->
      # Character name followed by a colon
      # [Character name] : some text

    for characterName in @characters
      if input.substr(0, characterName.length) is characterName
        @yytext = [characterName]
        result = ['CHARACTER_NAME']

        nextColon = @colonRegex.exec input[characterName.length..]
        if nextColon?.index is 0
          @yytext.push nextColon[0]
          result.push ':'
        return result
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