from rest_framework.viewsets import ModelViewSet
from rest_framework.permissions import IsAuthenticated

from myapp.models import Post
from myapp.serializers import PostSerializer

class PostViewSet(ModelViewSet):
    serializer_class = PostSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Post.objects.all().order_by('-created_at')
