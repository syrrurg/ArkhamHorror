module Arkham.Types.Event.Cards.ThePaintedWorld
  ( thePaintedWorld
  , ThePaintedWorld(..)
  ) where

import Arkham.Prelude

import qualified Arkham.Event.Cards as Cards
import Arkham.Types.Card
import Arkham.Types.Classes
import Arkham.Types.Event.Attrs
import Arkham.Types.Game.Helpers
import Arkham.Types.Message
import Arkham.Types.Source
import Arkham.Types.Target

newtype ThePaintedWorld = ThePaintedWorld EventAttrs
  deriving anyclass IsEvent
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

thePaintedWorld :: EventCard ThePaintedWorld
thePaintedWorld = event ThePaintedWorld Cards.thePaintedWorld

instance HasActions env ThePaintedWorld where
  getActions iid window (ThePaintedWorld attrs) = getActions iid window attrs

instance HasModifiersFor env ThePaintedWorld

instance CanCheckPlayable env => RunMessage env ThePaintedWorld where
  runMessage msg e@(ThePaintedWorld attrs) = case msg of
    InvestigatorPlayEvent iid eid _ windows | eid == toId attrs -> do
      underneathCards <- map unUnderneathCard <$> getList iid
      let
        validCards = filter
          (and . sequence
            [(== EventType) . toCardType, not . cdExceptional . toCardDef]
          )
          underneathCards
      playableCards <- filterM (getIsPlayable iid windows) validCards
      e <$ push
        (InitiatePlayCardAsChoose
          iid
          (toCardId attrs)
          (traceShowId playableCards)
          [ CreateEffect
              "03012"
              Nothing
              (CardIdSource $ toCardId attrs)
              (CardIdTarget $ toCardId attrs)
          ]
          True
        )
    _ -> ThePaintedWorld <$> runMessage msg attrs
