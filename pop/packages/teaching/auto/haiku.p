/* --- Copyright University of Birmingham 2003. All rights reserved. ------
 > File:			$poplocal/local/auto/haiku.p
 > Purpose:			Use storygrammar to generate Haikus
 > Author:			Aaron Sloman, Aug 29 2003
 > Documentation:	TEACH STORYGRAMMAR
 > Related Files:
 */


/*

Invoke as
	pop11 haiku 10

to get 10 haikus

*/




vars arg =
	if poparglist = [] then 5
	else strnumber(hd(poparglist))
	endif;

arg >< ' haikus requested\n\n' =>

uses grammar;
    uses grammar
    uses generate_category



    vars haiku_gram =
        [
            ;;; A "sentence" is a haiku, where
            ;;; a haiku has three parts separated by newlines
            [haiku [part1 ^newline part2 ^newline part3]]

            ;;; We now define the permitted forms for each part
            ;;; part2 will use different verbs (after the word "I")
            ;;; from the verbs in part3. The two sorts of verbs, and
            ;;; the adjectives and two sorts of nouns are listed in
            ;;; the lexicon, below.

            [ part1 [start_word adj in np]]

            [ part2 [I verb1 adj noun in np]]

            ;;; part3 has two forms, one with a singular noun phrase
            ;;; followed by "has" and the other with a plural noun
            ;;; phrase followed by "have"

            [ part3 [exclaim sing_np has verb2]
                    [exclaim plural_np have verb2]]

            ;;; different types of noun phrases, singular and plural
            ;;; use different kinds of nouns and different kinds of
            ;;; determiners
            [np [sing_np][plural_np]]

            [sing_np [sing_det sing_noun]]

            [plural_np [plural_det plural_noun]]

            ;;; Nouns can be singular or plural, defined in the
            ;;; lexicon
            [noun [sing_noun] [plural_noun]]
        ];

;;; This might be an example lexicon, for use with the above grammar

    vars haiku_lex =
        [
            ;;; adjectives (you could easily add more)
            [adj abrupt acrid angry avid bitter black bleak bleary
				crass crazy cyan dark deep
				eager eerie emerald empty evil
                flaccid flossy ghostly golden goulish
				grassy greenish
				hassty hardened heavy hoary
				idle inky
				languid lucid
				magenta morbid
				open opal
				plangent poetic purest
				rancid rapt
				sharply shiny smelly sordid starry sweetest
				tangled tinkling tiny twinkling
                vapid varied vicious
				weblike welling white zany zealous
            ]
            ;;; Words to start part 1
            [start_word Ages All Always And Eons If Many Most Often
				So Thus What When Where Who How Days But Yet Though
				Unless
				]

            ;;; Singular and plural determiners
            [sing_det the some one every each my her your our their
                this most mainly]

            [plural_det the some all most many my your our his their
                these those two three four every myriad ample]

            ;;; Singular and plural nouns. Add more
            [sing_noun acorn age anchor angel anguish autumn boat bridge
                canopy cosmos darkness dawn daylight
                death dew foal forest flurry grass greening
				harpy hatching
				infant insect spider
                laughter leaf life moon night
				ocean power river
                soul spring sunset tiger turmoil winter zoo]
            [plural_noun
                ancestors autumns
                births clouds collisions creatures
				dancers deaths devils dewdrops
                echoes evenings forms galaxies ghosts
                heavens hopers hosts jokes lawns
				paths poets planets
                raindrops rebirths rivers
				searchers seas seedlings spirits
                storms summers tangles tempests torments
                torrents trees verses vessels waves watchers winters
            ]
            [verb1 abandon anchor burn bury bundle
				carry compose covet crumple
				dangle detach deter defer devour
                excite eject empty engage enlarge enter entrap expect
				fetch fleece frame
                glaze grace grasp graze greet hug mourn
                plead please praise press sing sip slice smell
                spy stretch stroke
                taste tear tickle touch twist
                urge warn watch wear wipe
            ]

            [verb2 aged altered arisen
				bloomed blinked burnt burst
                chimed come cracked crazed drowned
                drooped dropped
                eaten ended eeked
                faded fallen failed fetched floundered frozen
                gone gripped groomed gushed held hated
                left loomed lost
                missed murdered netted notched nursed
                obeyed oiled opened oozed
                raided receded riddled ripped revived rode roped
                sang slept skipped smouldered swirled swarmed swung
                switched thawed waited watched wrested unzipped
            ]
            ;;; words for an exclamation
            [exclaim
                Aha Alas Albeit Aye Bang Bewail Crash Down Desist Ever
				Forever Ha Hey Ho Hoping Joking Joy Nay
                No Ouch Oh See So Pfft Rejoice Triumph Ugh Unless Until
				Well Wherefore Whisper Woe Yea Yes]
        ];

    ;;; set the maximum recursion level for the generator
    20 -> maxlevel;

    ;;; Generate arg haikus, using the above grammar and lexicon
    repeat arg times
        generate_category("haiku", haiku_gram, haiku_lex) ==>
		pr(newline);
    endrepeat;
