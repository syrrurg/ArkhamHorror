module Arkham.Scenario.Scenarios.TheUntamedWilds
  ( TheUntamedWilds(..)
  , theUntamedWilds
  ) where

import Arkham.Prelude

import Arkham.Act.Cards qualified as Acts
import Arkham.Act.Sequence qualified as AS
import Arkham.Act.Types
import Arkham.Agenda.Cards qualified as Agendas
import Arkham.Asset.Cards qualified as Assets
import Arkham.CampaignLogKey
import Arkham.Campaigns.TheForgottenAge.Helpers
import Arkham.Card
import Arkham.Classes
import Arkham.Difficulty
import Arkham.EncounterSet qualified as EncounterSet
import Arkham.Enemy.Cards qualified as Enemies
import Arkham.Game.Helpers
import Arkham.Helpers
import Arkham.Location.Cards qualified as Locations
import Arkham.Matcher
import Arkham.Message
import Arkham.Projection
import Arkham.Resolution
import Arkham.Scenario.Helpers
import Arkham.Scenario.Runner
import Arkham.ScenarioLogKey
import Arkham.Scenarios.TheUntamedWilds.Story
import Arkham.Target
import Arkham.Timing qualified as Timing
import Arkham.Token
import Arkham.Treachery.Cards qualified as Treacheries
import Arkham.Window ( Window (..) )
import Arkham.Window qualified as Window

newtype TheUntamedWilds = TheUntamedWilds ScenarioAttrs
  deriving anyclass (IsScenario, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

theUntamedWilds :: Difficulty -> TheUntamedWilds
theUntamedWilds difficulty = scenario
  TheUntamedWilds
  "04043"
  "The Untamed Wilds"
  difficulty
  [ ".               .             ruinsOfEztli   .               ."
  , ".               serpentsHaven ruinsOfEztli   circuitousTrail ."
  , "templeOfTheFang serpentsHaven riverCanyon    circuitousTrail overgrownRuins"
  , "templeOfTheFang pathOfThorns  riverCanyon    ropeBridge      overgrownRuins"
  , ".               pathOfThorns  expeditionCamp ropeBridge      ."
  , ".               .             expeditionCamp .               ."
  ]

instance HasTokenValue TheUntamedWilds where
  getTokenValue iid tokenFace (TheUntamedWilds attrs) = case tokenFace of
    Skull -> do
      vengeance <- getVengeanceInVictoryDisplay
      pure $ toTokenValue attrs Skull vengeance (vengeance + 1)
    Cultist -> do
      locationCount <- selectCount Anywhere
      pure $ toTokenValue attrs Cultist (min 5 locationCount) locationCount
    Tablet -> do
      explorationDeckCount <- length <$> getExplorationDeck
      pure $ toTokenValue
        attrs
        Tablet
        (min 5 explorationDeckCount)
        (max 3 explorationDeckCount)
    ElderThing -> do
      isPoisoned <- getIsPoisoned iid
      if isPoisoned
        then pure $ TokenValue ElderThing AutoFailModifier
        else pure $ toTokenValue attrs ElderThing 2 3
    otherFace -> getTokenValue iid otherFace attrs

instance RunMessage TheUntamedWilds where
  runMessage msg s@(TheUntamedWilds attrs) = case msg of
    Setup -> do
      investigatorIds <- getInvestigatorIds
      expeditionCamp <- genCard Locations.expeditionCamp

      explorationDeck <- shuffleM =<< traverse
        genCard
        [ Locations.pathOfThorns
        , Locations.riverCanyon
        , Locations.ropeBridge
        , Locations.serpentsHaven
        , Locations.circuitousTrail
        , Treacheries.lostInTheWilds
        , Treacheries.overgrowth
        , Treacheries.snakeBite
        , Treacheries.lowOnSupplies
        , Treacheries.arrowsFromTheTrees
        ]
      agentsOfYig <- map EncounterCard
        <$> gatherEncounterSet EncounterSet.AgentsOfYig
      setAsideCards <- (agentsOfYig <>) <$> traverse
        genCard
        [ Locations.ruinsOfEztli
        , Locations.templeOfTheFang
        , Locations.overgrownRuins
        , Enemies.ichtaca
        , Treacheries.poisoned
        , Treacheries.poisoned
        , Treacheries.poisoned
        , Treacheries.poisoned
        ]
      encounterDeck <- buildEncounterDeckExcluding
        [ Enemies.ichtaca
        , Locations.pathOfThorns
        , Locations.riverCanyon
        , Locations.ropeBridge
        , Locations.serpentsHaven
        , Locations.circuitousTrail
        , Locations.ruinsOfEztli
        , Locations.templeOfTheFang
        , Locations.overgrownRuins
        ]
        [ EncounterSet.TheUntamedWilds
        , EncounterSet.Rainforest
        , EncounterSet.Serpents
        , EncounterSet.Expedition
        , EncounterSet.GuardiansOfTime
        , EncounterSet.Poison
        , EncounterSet.AncientEvils
        ]
      let
        encounterDeck' = flip withDeck encounterDeck $ \cards -> foldl'
          (\cs m -> deleteFirstMatch ((== m) . toCardDef) cs)
          cards
          [ Treacheries.lostInTheWilds
          , Treacheries.overgrowth
          , Treacheries.snakeBite
          , Treacheries.lowOnSupplies
          , Treacheries.arrowsFromTheTrees
          ]
      pushAll
        $ [ story investigatorIds intro
          , SetEncounterDeck encounterDeck'
          , SetAgendaDeck
          , SetActDeck
          , PlaceLocation expeditionCamp
          , MoveAllTo (toSource attrs) (toLocationId expeditionCamp)
          ]
      TheUntamedWilds <$> runMessage
        msg
        (attrs
        & (decksL . at ExplorationDeck ?~ explorationDeck)
        & (setAsideCardsL .~ setAsideCards)
        & (actStackL
          . at 1
          ?~ [ Acts.exploringTheRainforest
             , Acts.huntressOfTheEztli
             , Acts.searchForTheRuins
             , Acts.theGuardedRuins
             ]
          )
        & (agendaStackL
          . at 1
          ?~ [Agendas.expeditionIntoTheWild, Agendas.intruders]
          )
        )
    FailedSkillTest iid _ _ (TokenTarget token) _ _ -> case tokenFace token of
      ElderThing -> do
        isPoisoned <- getIsPoisoned iid
        unless isPoisoned $ do
          poisoned <- getSetAsidePoisoned
          push $ CreateWeaknessInThreatArea poisoned iid
        pure s
      _ -> pure s
    Explore iid _ _ -> do
      windowMsg <- checkWindows [Window Timing.When $ Window.AttemptExplore iid]
      pushAll [windowMsg, Do msg]
      pure s
    Do (Explore iid source locationMatcher) -> do
      explore iid source locationMatcher
      pure s
    ScenarioResolution res -> do
      investigatorIds <- getInvestigatorIds
      actStep <- fieldMap ActSequence (AS.unActStep . AS.actStep)
        =<< selectJust AnyAct
      xp <- getXp
      vengeance <- getVengeanceInVictoryDisplay
      leadInvestigatorId <- getLeadInvestigatorId
      case res of
        NoResolution -> do
          foughtWithIchtaca <- remembered YouFoughtWithIchtaca
          leadingTheWay <- remembered IchtachaIsLeadingTheWay
          pushAll
            $ [ story investigatorIds noResolution
              , Record TheInvestigatorsWereForcedToWaitForAdditionalSupplies
              ]
            <> [ Record IchtacaObservedYourProgressWithKeenInterest
               | actStep `elem` [1, 2]
               ]
            <> [ Record IchtacaIsWaryOfTheInvestigators | foughtWithIchtaca ]
            <> [ Record AlejandroFollowedTheInvestigatorsIntoTheRuins
               | actStep `elem` [1, 2] || foughtWithIchtaca
               ]
            <> [ addCampaignCardToDeckChoice
                   leadInvestigatorId
                   investigatorIds
                   Assets.alejandroVela
               ]
            <> [ Record TheInvestigatorsHaveEarnedIchtacasTrust
               | leadingTheWay
               ]
            <> [ Record AlejandroChoseToRemainAtCamp | leadingTheWay ]
            <> [RecordCount YigsFury vengeance]
            <> [ GainXP iid n | (iid, n) <- xp ]
        Resolution 1 -> do
          pushAll
            $ [ story investigatorIds resolution1
              , Record TheInvestigatorsClearedAPathToTheEztliRuins
              , Record AlejandroChoseToRemainAtCamp
              , Record TheInvestigatorsHaveEarnedIchtacasTrust
              , RecordCount YigsFury vengeance
              ]
            <> [ GainXP iid n | (iid, n) <- xp ]
        Resolution 2 -> do
          pushAll
            $ [ story investigatorIds resolution2
              , Record TheInvestigatorsClearedAPathToTheEztliRuins
              , Record AlejandroFollowedTheInvestigatorsIntoTheRuins
              ]
            <> [ addCampaignCardToDeckChoice
                   leadInvestigatorId
                   investigatorIds
                   Assets.alejandroVela
               ]
            <> [ Record IchtacaIsWaryOfTheInvestigators
               , RecordCount YigsFury vengeance
               ]
            <> [ GainXP iid n | (iid, n) <- xp ]
        _ -> error "invalid resolution"
      pure s
    _ -> TheUntamedWilds <$> runMessage msg attrs
