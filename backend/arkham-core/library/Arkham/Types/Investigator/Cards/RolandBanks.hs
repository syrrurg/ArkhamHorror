module Arkham.Types.Investigator.Cards.RolandBanks
  ( RolandBanks(..)
  , rolandBanks
  ) where

import Arkham.Prelude

import Arkham.Investigator.Cards qualified as Cards
import Arkham.Types.Ability
import Arkham.Types.Classes
import Arkham.Types.Cost
import Arkham.Types.Criteria
import Arkham.Types.Id
import Arkham.Types.Investigator.Attrs
import Arkham.Types.Matcher
import Arkham.Types.Message hiding (EnemyDefeated)
import Arkham.Types.Query
import Arkham.Types.Timing qualified as Timing

newtype RolandBanks = RolandBanks InvestigatorAttrs
  deriving anyclass (IsInvestigator, HasModifiersFor env)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

rolandBanks :: InvestigatorCard RolandBanks
rolandBanks = investigator RolandBanks Cards.rolandBanks
  Stats
    { health = 9
    , sanity = 5
    , willpower = 3
    , intellect = 3
    , combat = 4
    , agility = 2
    }

instance HasAbilities RolandBanks where
  getAbilities (RolandBanks a) =
    [ reaction a 1 (OnLocation LocationWithAnyClues) Free
        (EnemyDefeated Timing.After You AnyEnemy)
        & (abilityLimitL .~ PlayerLimit PerRound 1)
    ]

instance HasCount ClueCount env LocationId => HasTokenValue env RolandBanks where
  getTokenValue (RolandBanks attrs) iid ElderSign | iid == toId attrs = do
    locationClueCount <- unClueCount <$> getCount (investigatorLocation attrs)
    pure $ TokenValue ElderSign (PositiveModifier locationClueCount)
  getTokenValue _ _ token = pure $ TokenValue token mempty

instance InvestigatorRunner env => RunMessage env RolandBanks where
  runMessage msg rb@(RolandBanks a) = case msg of
    UseCardAbility _ source _ 1 _ | isSource a source -> rb <$ push
      (DiscoverCluesAtLocation (toId a) (investigatorLocation a) 1 Nothing)
    _ -> RolandBanks <$> runMessage msg a
