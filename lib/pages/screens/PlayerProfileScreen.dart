import 'package:flutter/material.dart';
import 'package:Frutia/auth/auth_service.dart';

class PlayerProfileScreen extends StatefulWidget {
  final int userId;

  const PlayerProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _PlayerProfileScreenState createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    _profileFuture = AuthService().getProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error cargando perfil'));
          }

          final userData = snapshot.data!;
          
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildProfileHeader(userData),
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: 'Estadísticas'),
                      Tab(text: 'Partidos'),
                      Tab(text: 'Logros'),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildStatsTab(userData),
          //      _buildMatchesTab(userData),
            //    _buildAchievementsTab(userData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    String? imageUrl = userData['profile_image'] != null
        ? 'https://proyect.aftconta.mx/storage/${userData['profile_image']}'
        : null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue, Colors.blue.shade800],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
            child: imageUrl == null ? Icon(Icons.person, size: 50) : null,
          ),
          SizedBox(height: 16),
          Text(
            userData['name'],
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            userData['position'] ?? 'Sin posición',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(Map<String, dynamic> userData) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildStatCard(
          'Estadísticas Generales',
          [
            _buildStatItem('Partidos Jugados', '${userData['total_matches'] ?? 0}'),
            _buildStatItem('Promedio Calificación', '${userData['average_rating'] ?? 0.0}'),
            _buildStatItem('MVP', '${userData['mvp_count'] ?? 0} veces'),
          ],
        ),
        SizedBox(height: 16),
        _buildStatCard(
          'Últimos Partidos',
          [
            _buildStatItem('Ganados', '75%'),
            _buildStatItem('Perdidos', '25%'),
            _buildStatItem('Goles', '12'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, List<Widget> stats) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(),
            ...stats,
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

 }
 class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override 
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}