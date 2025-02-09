from rest_framework.viewsets import ModelViewSet
from rest_framework.permissions import IsAuthenticated
from rest_framework import status, serializers
from rest_framework.response import Response
from rest_framework.views import APIView

from myapp.models import Post, Comment
from myapp.serializers import PostSerializer, LikePostSerializer, CommentSerializer
from authentication.serializers import UserSerializer

class PostViewSet(ModelViewSet):
    serializer_class = PostSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = Post.objects.all().order_by('-created_at')
        author_id = self.request.query_params.get("author_id", None)

        if author_id:
            queryset = queryset.filter(author__id=author_id).order_by('-created_at')

        return queryset

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)

    def update(self, request, *args, **kwargs):
        """ Seul l'auteur ou un admin peut modifier un post """
        post = self.get_object()
        if request.user == post.author or request.user.is_superuser:
            return super().update(request, *args, **kwargs)
        return Response(
            {"detail": "Vous n'avez pas la permission de modifier ce post."},
            status=status.HTTP_403_FORBIDDEN
        )

    def partial_update(self, request, *args, **kwargs):
        post = self.get_object()
        if request.user == post.author or request.user.is_superuser:
            return super().partial_update(request, *args, **kwargs)
        return Response(
            {"detail": "Vous n'avez pas la permission de modifier ce post."},
            status=status.HTTP_403_FORBIDDEN
        )

    def destroy(self, request, *args, **kwargs):
        """ Seul l'auteur ou un admin peut supprimer un post """
        post = self.get_object()
        if request.user == post.author or request.user.is_superuser:
            return super().destroy(request, *args, **kwargs)
        return Response(
            {"detail": "Vous n'avez pas la permission de supprimer ce post."},
            status=status.HTTP_403_FORBIDDEN
        )

class LikePostView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, post_id):

        try:
            post = Post.objects.get(id=post_id)

            # Trier les likes du post du plus récent au plus ancien
            likes = post.likes.through.objects.filter(post=post).order_by('-created_at')

            # Récupérer les utilisateurs ayant liké, triés par date du like
            users = [like.user for like in likes]

            # Sérialiser les utilisateurs
            like_user_data = UserSerializer(users, many=True).data

            # Sérialiser le post avec les likes
            serializer = LikePostSerializer(post, context={"request": request})

            # Ajouter la liste des utilisateurs ayant liké
            serializer.data['likes'] = like_user_data

            return Response(serializer.data, status=status.HTTP_200_OK)

        except Post.DoesNotExist:
            return Response({"error": "Post non trouvé"}, status=status.HTTP_404_NOT_FOUND)

    def put(self, request, post_id):
        """Liker ou unliker un post et retourner la liste des utilisateurs ayant liké"""
        try:
            post = Post.objects.get(id=post_id)
            user = request.user

            if post.likes.filter(id=user.id).exists():
                post.likes.remove(user)  # Supprime le like
            else:
                post.likes.add(user)  # Ajoute le like

            serializer = LikePostSerializer(post, context={"request": request})
            return Response(serializer.data, status=status.HTTP_200_OK)

        except Post.DoesNotExist:
            return Response({"error": "Post non trouvé"}, status=status.HTTP_404_NOT_FOUND)

class CommentViewSet(ModelViewSet):

    serializer_class = CommentSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Filtrer les commentaires en fonction du post_id passé en paramètre."""
        post_id = self.request.query_params.get('post_id')  # Récupérer le post_id depuis l'URL
        if post_id:
            return Comment.objects.filter(post_id=post_id).order_by('-created_at')
        return Comment.objects.all().order_by('-created_at')

    def perform_create(self, serializer):
        post_id = self.request.query_params.get('post_id')

        if not post_id:
            raise serializers.ValidationError({"error": "post_id est requis."})

        try:
            post = Post.objects.get(id=post_id)
        except Post.DoesNotExist:
            raise serializers.ValidationError({"error": "Post non trouvé."})

        serializer.save(post=post, author=self.request.user)


    def update(self, request, *args, **kwargs):
        comment = self.get_object()
        if request.user == comment.author or request.user.is_superuser:
            return super().update(request, *args, **kwargs)
        return Response(
            {"detail": "Vous n'avez pas la permission de modifier ce commentaire."},
            status=status.HTTP_403_FORBIDDEN
        )

    def partial_update(self, request, *args, **kwargs):
        comment = self.get_object()
        if request.user == comment.author or request.user.is_superuser:
            return super().partial_update(request, *args, **kwargs)
        return Response(
            {"detail": "Vous n'avez pas la permission de modifier ce commentaire."},
            status=status.HTTP_403_FORBIDDEN
        )

    def destroy(self, request, *args, **kwargs):
        """ Seul l'auteur ou un admin peut supprimer un post """
        comment = self.get_object()
        if request.user == comment.author or request.user.is_superuser:
            return super().destroy(request, *args, **kwargs)
        return Response(
            {"detail": "Vous n'avez pas la permission de supprimer ce commentaire."},
            status=status.HTTP_403_FORBIDDEN
        )
