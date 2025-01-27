from rest_framework.viewsets import ModelViewSet
from rest_framework.permissions import IsAuthenticated, AllowAny

from authentication.serializers import UserSerializer
from authentication.models import User

class UserViewSet(ModelViewSet):

    serializer_class = UserSerializer

    # def get_permissions(self):

    #     if self.action == 'create':
    #         permission_classes = [AllowAny]
    #     else:
    #         permission_classes = [IsAuthenticated]

    #     return [permission() for permission in permission_classes]

    def get_queryset(self):
        # if self.request.user.is_superuser:  # Si l'utilisateur est admin, il voit tout
        #     return User.objects.all()
        # return User.objects.filter(id=self.request.user.id)  # Sinon, uniquement ses propres données
        return User.objects.all()

