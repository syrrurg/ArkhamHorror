module Arkham.Internal.ChaosToken
  ( modifier
  , elderSignToken
  , autoFailToken
  , plusOneToken
  , zeroToken
  , minusOneToken
  , minusTwoToken
  , minusThreeToken
  , minusFourToken
  , minusFiveToken
  , minusSixToken
  , minusSevenToken
  , minusEightToken
  )
where

import Arkham.Constructors
import Arkham.Internal.Investigator
import Arkham.Internal.Types
import Arkham.Types.ChaosToken
import Arkham.Types.Player
import ClassyPrelude
import Safe (fromJustNote)

modifier :: Int -> (a -> b -> ArkhamChaosTokenResult)
modifier = const . const . Modifier

numberToken :: Int -> ArkhamChaosTokenInternal
numberToken n = (token $ fromJustNote "Not a valid number token" $ tokenType n)
  { tokenToResult = modifier n
  }
 where
  tokenType 1 = Just PlusOne
  tokenType 0 = Just Zero
  tokenType (-1) = Just MinusOne
  tokenType (-2) = Just MinusTwo
  tokenType (-3) = Just MinusThree
  tokenType (-4) = Just MinusFour
  tokenType (-5) = Just MinusFive
  tokenType (-6) = Just MinusSix
  tokenType (-7) = Just MinusSeven
  tokenType (-8) = Just MinusEight
  tokenType _ = Nothing


plusOneToken :: ArkhamChaosTokenInternal
plusOneToken = numberToken 1

zeroToken :: ArkhamChaosTokenInternal
zeroToken = numberToken 0

minusOneToken :: ArkhamChaosTokenInternal
minusOneToken = numberToken (-1)

minusTwoToken :: ArkhamChaosTokenInternal
minusTwoToken = numberToken (-2)

minusThreeToken :: ArkhamChaosTokenInternal
minusThreeToken = numberToken (-3)

minusFourToken :: ArkhamChaosTokenInternal
minusFourToken = numberToken (-4)

minusFiveToken :: ArkhamChaosTokenInternal
minusFiveToken = numberToken (-5)

minusSixToken :: ArkhamChaosTokenInternal
minusSixToken = numberToken (-6)

minusSevenToken :: ArkhamChaosTokenInternal
minusSevenToken = numberToken (-7)

minusEightToken :: ArkhamChaosTokenInternal
minusEightToken = numberToken (-7)

autoFailToken :: ArkhamChaosTokenInternal
autoFailToken = (token AutoFail) { tokenToResult = const (const Failure) }

playerElderSignToken :: ArkhamPlayer -> ArkhamChaosTokenInternal
playerElderSignToken = investigatorElderSignToken . toInternalInvestigator

elderSignToken :: ArkhamChaosTokenInternal
elderSignToken = ArkhamChaosTokenInternal
  { tokenToResult = \g p -> tokenToResult (playerElderSignToken p) g p
  , tokenOnFail = \g p -> tokenOnFail (playerElderSignToken p) g p
  , tokenOnSuccess = \g p -> tokenOnSuccess (playerElderSignToken p) g p
  , tokenOnReveal = \g p -> tokenOnReveal (playerElderSignToken p) g p
  }
