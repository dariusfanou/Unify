from rest_framework.viewsets import ModelViewSet
from rest_framework.permissions import IsAuthenticated
from rest_framework import status, serializers
from rest_framework.response import Response
from rest_framework.views import APIView

from myapp.models import Post, Comment, Notification, Message
from myapp.serializers import PostSerializer, LikePostSerializer, CommentSerializer, NotificationSerializer, MessageSerializer
from authentication.serializers import UserSerializer

from django.db.models import Q
from unidecode import unidecode

from authentication.models import User

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
                post.likes.remove(user)
            else:
                post.likes.add(user)

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

class SearchView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, *args, **kwargs):
        query = request.query_params.get('q', '')  # La recherche est passée dans les paramètres de requête

        if query:
            # Prépare la query en la normalisant (en minuscules et sans accents)
            normalized_query = unidecode(query.lower())

            # Recherche dans les utilisateurs (username) sans différence entre majuscules/minuscules et sans accents
            users = User.objects.filter(
                Q(username__icontains=normalized_query) |
                Q(username__iexact=normalized_query)
            )

            # Recherche dans les posts (content) sans différence entre majuscules/minuscules et sans accents
            posts = Post.objects.filter(
                Q(content__icontains=normalized_query) |
                Q(content__iexact=normalized_query)
            )

            # Sérialise les résultats
            user_serializer = UserSerializer(users, many=True)
            post_serializer = PostSerializer(posts, many=True)

            return Response({
                'users': user_serializer.data,
                'posts': post_serializer.data
            })

        return Response({
            'message': 'Aucune requête fournie'
        }, status=status.HTTP_400_BAD_REQUEST)

class NotificationViewSet(ModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(receiver=self.request.user).order_by('-created_at')

    def perform_create(self, serializer):
        serializer.save(sender=self.request.user)

    def partial_update(self, request, *args, **kwargs):
        notification = self.get_object()
        if request.user == notification.receiver or request.user.is_superuser:
            return super().partial_update(request, *args, **kwargs)
        return Response(
            {"detail": "Vous n'avez pas la permission de modifier cette notification."},
            status=status.HTTP_403_FORBIDDEN
        )

    def destroy(self, request, *args, **kwargs):
        notification = self.get_object()
        if request.user == notification.receiver or request.user.is_superuser:
            return super().destroy(request, *args, **kwargs)
        return Response(
            {"detail": "Vous n'avez pas la permission de supprimer cette notification."},
            status=status.HTTP_403_FORBIDDEN
        )

class MessageViewSet(ModelViewSet):
    queryset = Message.objects.all()
    serializer_class = MessageSerializer
