module Arkham.Location.Cards.Bedroom where

import Arkham.Prelude

import Arkham.Ability
import Arkham.Classes
import Arkham.GameValue
import Arkham.Location.Cards qualified as Cards ( bedroom )
import Arkham.Location.Helpers
import Arkham.Location.Runner
import Arkham.Matcher
import Arkham.Message
import Arkham.Timing qualified as Timing

newtype Bedroom = Bedroom LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

bedroom :: LocationCard Bedroom
bedroom = location Bedroom Cards.bedroom 2 (PerPlayer 1)

instance HasAbilities Bedroom where
  getAbilities (Bedroom attrs) =
    withBaseAbilities attrs
      $ [ mkAbility attrs 1
          $ ForcedAbility
          $ SkillTestResult
              Timing.After
              You
              (WhileInvestigating $ LocationWithId $ toId attrs)
          $ FailureResult AnyValue
        | locationRevealed attrs
        ]

instance RunMessage Bedroom where
  runMessage msg l@(Bedroom attrs) = case msg of
    UseCardAbility iid source 1 _ _ | isSource attrs source ->
      l <$ push (RandomDiscard iid (toAbilitySource attrs 1) AnyCard)
    _ -> Bedroom <$> runMessage msg attrs
